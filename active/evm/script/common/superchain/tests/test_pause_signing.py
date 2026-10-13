import os
from pathlib import Path
import select
import shutil
import signal
import subprocess
import tempfile
import unittest


COMMON = Path(__file__).resolve().parents[1]
REPO = COMMON.parents[4]
SIGNER = "0x" + "ab" * 20

FAKE_TOOL = r'''#!/usr/bin/env bash
set -eu
case ${0##*/} in
    mise)
        case $1 in
            trust|install) ;;
            exec)
                shift 2
                case $1 in
                    go|cast|"$FIXTURE/goroot/bin/eip712sign") exec "$@" ;;
                    *) exit 1 ;;
                esac
                ;;
            *) exit 1 ;;
        esac
        ;;
    go)
        if [[ $1 == env && $2 == GOROOT ]]; then
            echo "$FIXTURE/goroot"
        elif [[ $1 == install ]]; then
            mkdir -p "$GOBIN"
            cp "$FIXTURE/bin/fake-tool" "$GOBIN/eip712sign"
        else
            exit 1
        fi
        ;;
    cast)
        case $1 in
            call)
                case $3 in
                    'nonce()') printf '0x%064x\n' "${START_NONCE:-7}" ;;
                    superchainConfig*) printf '0x%040x\n' 205 ;;
                    domainSeparator*) printf '0x%064x\n' 222 ;;
                    *) exit 1 ;;
                esac
                ;;
            chain-id) echo 1 ;;
            to-dec) echo "$(( $2 ))" ;;
            calldata) echo 0x1234 ;;
            abi-encode) printf '0x%064x\n' "${!#}" ;;
            keccak) if [[ ${#2} == 66 ]]; then echo "$2"; else printf '0x%064x\n' 239; fi ;;
            *) exit 1 ;;
        esac
        ;;
    mkdir)
        if [[ ${LOCK_GATE:-} && $1 == config/mainnet/.pause-signing.lock ]]; then
            printf 1 > "$FIXTURE/lock-ready"
            IFS= read -r -t 30 _ < "$FIXTURE/lock-release"
        fi
        exec "$REAL_MKDIR" "$@"
        ;;
    eip712sign)
        data=${!#}
        nonce=$((16#${data: -8}))
        previous=false
        if [[ -f $FIXTURE/attempts ]] && grep -qx "$nonce" "$FIXTURE/attempts"; then previous=true; fi
        echo "$nonce" >> "$FIXTURE/attempts"
        if [[ ${SIGNING_GATE:-} && $nonce == 7 ]]; then
            printf 1 > "$FIXTURE/sign-ready"
            IFS= read -r -t 30 _ < "$FIXTURE/sign-release"
        fi
        printf -v signature '%0128x1b' "$nonce"
        echo 'Signer: 0xabababababababababababababababababababab'
        echo "Signature: $signature"
        echo "Signature: $signature" >&2
        if [[ ${FAIL_NONCE:-} == "$nonce" && ( ${FAIL_ALWAYS:-} || $previous == false ) ]]; then exit 1; fi
        ;;
    *) exit 1 ;;
esac
'''


class PauseSigningTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.task = Path(self.tmp.name)
        tools = self.task / "bin"
        tools.mkdir()
        fake = tools / "fake-tool"
        fake.write_text(FAKE_TOOL)
        fake.chmod(0o755)
        for tool in ("mise", "go", "cast", "mkdir"):
            (tools / tool).symlink_to(fake)
        self.config = self.task / "config/mainnet"
        self.config.mkdir(parents=True)
        (self.config / ".env").write_text(
            f"L1_RPC_URL=mainnet\nLEDGER_ACCOUNT=0\n"
            f"INCIDENT_MULTISIG=0x{'aa' * 20}\nSYSTEM_CONFIG=0x{'bb' * 20}\n"
        )
        (self.task / "Makefile").write_text(
            f"include {REPO}/Makefile\ninclude {COMMON}/PauseSigning.mk\n"
            "include config/$(TASK_NETWORK)/.env\n"
        )
        self.env = dict(PATH=f"{tools}:{os.defpath}", HOME=str(self.task),
                        FIXTURE=str(self.task), GOPATH=str(self.task / "gopath"),
                        GOBIN=str(self.task / "unrelated-bin"),
                        REAL_MKDIR=shutil.which("mkdir", path=os.defpath))
        self.command = ["make", "--no-print-directory", "TASK_NETWORK=mainnet", "sign-pause"]

    def make(self, **env):
        return subprocess.run(self.command, cwd=self.task, env=dict(self.env, **env),
                              text=True, stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              timeout=60)

    def attempts(self):
        return [int(n) for n in (self.task / "attempts").read_text().splitlines()]

    def assert_batch(self, start=7):
        entries = (self.config / "signatures-pause.txt").read_text().strip().split(",")
        self.assertEqual(entries, [f"{SIGNER}:{nonce}:{nonce:0128x}1b"
                                   for nonce in range(start, start + 20)] + [""])
        self.assertEqual(sorted(p.name for p in self.config.iterdir()),
                         [".env", "signatures-pause.txt"])
        return [entry.split(":")[2] for entry in entries[:-1]]

    def test_transient_failure_retries_same_nonce_and_keeps_exact_batch(self):
        result = self.make(FAIL_NONCE="10")
        self.assertEqual(result.returncode, 0, result.stdout)
        signatures = self.assert_batch()
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10] + list(range(11, 27)))
        self.assertTrue(all(sig not in result.stdout for sig in signatures))
        self.assertNotIn("Signature:", result.stdout)
        self.assertIn("Send the contents of config/mainnet/signatures-pause.txt", result.stdout)
        self.assertFalse((self.task / "signatures-pause.txt").exists())
        self.assertFalse((self.task / "sign_output.tmp").exists())

    def test_nonce_10000_bounded_failure_preserves_progress_and_rerun_resumes(self):
        failed = self.make(START_NONCE="10000", FAIL_NONCE="10003", FAIL_ALWAYS="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn("Stopped at nonce 10003 after 3 attempts", failed.stdout)
        self.assertEqual(self.attempts(), [10000, 10001, 10002] + [10003] * 3)
        self.assertFalse((self.config / "signatures-pause.txt").exists())
        self.assertIn("make TASK_NETWORK=mainnet sign-pause", failed.stdout)
        self.assertIn("Do not send partial signatures", failed.stdout)
        self.assertNotIn("Signature:", failed.stdout)
        state = self.config / ".pause-signing"
        self.assertEqual(sorted(p.name for p in state.iterdir()), ["0", "1", "2", "context"])
        self.assertEqual([(state / str(i)).read_text() for i in range(3)],
                         [f"{SIGNER}:{n}:{n:0128x}1b\n" for n in range(10000, 10003)])
        self.assertFalse((self.config / ".pause-signing.lock").exists())
        resumed = self.make(START_NONCE="10000")
        self.assertEqual(resumed.returncode, 0, resumed.stdout)
        self.assert_batch(start=10000)
        self.assertEqual(self.attempts(), [10000, 10001, 10002] + [10003] * 3 + list(range(10003, 10020)))

    def test_completed_batch_cannot_be_overwritten_even_after_delayed_lock(self):
        gates = {}
        for name in ("sign-ready", "sign-release", "lock-ready", "lock-release"):
            path = self.task / name
            os.mkfifo(path)
            gates[name] = os.open(path, os.O_RDWR | os.O_NONBLOCK)
            self.addCleanup(os.close, gates[name])

        processes = []

        def launch(**env):
            process = subprocess.Popen(
                self.command, cwd=self.task, env=dict(self.env, **env), text=True,
                stdin=subprocess.DEVNULL, start_new_session=True,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            )
            processes.append(process)
            return process

        def await_gate(name):
            ready, _, _ = select.select([gates[name]], [], [], 30)
            self.assertTrue(ready, f"Timed out waiting for {name}")
            self.assertEqual(os.read(gates[name], 1), b"1")

        try:
            first = launch(SIGNING_GATE="1")
            await_gate("sign-ready")
            second = launch(LOCK_GATE="1")
            await_gate("lock-ready")
            # Delay lock acquisition until the first run has published and unlocked.
            self.assertTrue((self.config / ".pause-signing.lock").is_dir())
            os.write(gates["sign-release"], b"go\n")
            first_output, _ = first.communicate(timeout=60)
            self.assertEqual(first.returncode, 0, first_output)
            output = self.task / "config/mainnet/signatures-pause.txt"
            original = output.read_bytes()
            self.assertFalse((self.config / ".pause-signing.lock").exists())
            os.write(gates["lock-release"], b"go\n")
            second_output, _ = second.communicate(timeout=60)
            self.assertNotEqual(second.returncode, 0, second_output)
            self.assertIn("already exists", second_output)
            self.assertEqual(output.read_bytes(), original)
            self.assert_batch()
            again = self.make(START_NONCE="50")
            self.assertNotEqual(again.returncode, 0, again.stdout)
            self.assertIn("already exists", again.stdout)
            self.assertEqual(output.read_bytes(), original)
        finally:
            for process in processes:
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
                process.communicate(timeout=60)

    def test_changed_safe_nonce_cannot_mix_with_partial_batch(self):
        self.assertNotEqual(self.make(FAIL_NONCE="10", FAIL_ALWAYS="1").returncode, 0)
        state = self.config / ".pause-signing"
        before = {p.name: p.read_bytes() for p in state.iterdir()}
        changed = self.make(START_NONCE="8")
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("context changed", changed.stdout)
        self.assertEqual({p.name: p.read_bytes() for p in state.iterdir()}, before)
        self.assertFalse((self.config / "signatures-pause.txt").exists())


if __name__ == "__main__":
    unittest.main()
