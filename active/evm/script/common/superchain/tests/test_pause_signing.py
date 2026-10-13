from contextlib import contextmanager
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import subprocess
import tempfile
import time
import unittest


COMMON = Path(__file__).resolve().parents[1]
REPO = COMMON.parents[4]
SIGNER = "0x" + "ab" * 20

FAKE_TOOL = r'''#!/usr/bin/env bash
set -eu
case ${0##*/} in
    mise)
        if [[ $1 == exec ]]; then shift 2; exec "$@"; fi
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
                    nonce*) echo "${START_NONCE:-7}" ;;
                    superchainConfig*) printf '0x%040x\n' 205 ;;
                    domainSeparator*) printf '0x%064x\n' 222 ;;
                    *) exit 1 ;;
                esac
                ;;
            chain-id) if [[ $3 == mainnet ]]; then echo 1; else echo 11155111; fi ;;
            to-dec) echo "$2" ;;
            calldata) echo 0x1234 ;;
            abi-encode) printf '0x%064x\n' "${!#}" ;;
            keccak) if [[ ${#2} == 66 ]]; then echo "$2"; else printf '0x%064x\n' 239; fi ;;
            *) exit 1 ;;
        esac
        ;;
    mkdir)
        if [[ ${LOCK_GATE:-} && $1 == config/mainnet/.pause-signing.lock ]]; then
            printf 1 > "$FIXTURE/lock-ready"
            IFS= read -r _ < "$FIXTURE/lock-release"
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
            IFS= read -r _ < "$FIXTURE/sign-release"
        fi
        printf -v signature '%0128x1b' "$nonce"
        if [[ ${MALFORMED_NONCE:-} == "$nonce" ]]; then
            case ${MALFORMED_OUTPUT:-duplicate} in
                truncated) signature=${signature:1} ;;
                nonhex) signature="g${signature:1}" ;;
            esac
        fi
        echo 'Signer: 0xabababababababababababababababababababab'
        echo "Signature: $signature"
        echo "Signature: $signature" >&2
        if [[ ${LOCKED_NONCE:-} == "$nonce" && -f $FIXTURE/ledger-locked ]]; then exit 1; fi
        if [[ ${FAIL_NONCE:-} == "$nonce" && ( ${FAIL_ALWAYS:-} || $previous == false ) ]]; then exit 1; fi
        if [[ ${MALFORMED_NONCE:-} == "$nonce" && ${MALFORMED_OUTPUT:-duplicate} == duplicate ]]; then
            echo 'Signature: malformed'
        fi
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
        for network in ("mainnet", "sepolia"):
            config = self.task / "config" / network
            config.mkdir(parents=True)
            (config / ".env").write_text(
                f"L1_RPC_URL={network}\nLEDGER_ACCOUNT=0\n"
                f"INCIDENT_MULTISIG=0x{'aa' * 20}\nSYSTEM_CONFIG=0x{'bb' * 20}\n"
            )
        (self.task / "Makefile").write_text(
            f"include {REPO}/Makefile\ninclude {COMMON}/PauseSigning.mk\n"
            "include config/$(TASK_NETWORK)/.env\n"
        )
        self.env = dict(os.environ, PATH=f"{tools}:{os.environ['PATH']}",
                        FIXTURE=str(self.task), GOPATH=str(self.task / "gopath"),
                        GOBIN=str(self.task / "unrelated-bin"),
                        REAL_MKDIR=shutil.which("mkdir"))

    def make(self, network="mainnet", **env):
        args = ["make", "--no-print-directory"]
        if network is not None:
            args.append(f"TASK_NETWORK={network}")
        return subprocess.run(args + ["sign-pause"], cwd=self.task,
                              env=dict(self.env, **env), text=True,
                              stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              timeout=60)

    @contextmanager
    def interactive_make(self, **env):
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(
                ["make", "--no-print-directory", "TASK_NETWORK=mainnet", "sign-pause"],
                cwd=self.task, env=dict(self.env, **env), stdin=slave,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                start_new_session=True, bufsize=0,
            )
        finally:
            os.close(slave)
        try:
            yield process, master
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
            process.communicate(timeout=60)
            os.close(master)

    def await_retry_prompt(self, process, attempt):
        prompt = f"Press Enter to retry nonce 10 (attempt {attempt}/3)".encode()
        output = b""
        deadline = time.monotonic() + 30
        while prompt not in output:
            ready, _, _ = select.select([process.stdout], [], [], max(0, deadline - time.monotonic()))
            self.assertTrue(ready, f"Timed out waiting for retry prompt: {output.decode()}")
            chunk = os.read(process.stdout.fileno(), 4096)
            self.assertTrue(chunk, f"Signing exited without retry prompt: {output.decode()}")
            output += chunk
        return output

    def attempts(self):
        return [int(n) for n in (self.task / "attempts").read_text().splitlines()]

    def assert_batch(self, network, start=7):
        config = self.task / "config" / network
        entries = (config / "signatures-pause.txt").read_text().strip().strip(",").split(",")
        self.assertEqual(len(entries), 20)
        self.assertEqual([int(e.split(":")[1]) for e in entries], list(range(start, start + 20)))
        self.assertTrue(all(e.split(":")[0] == SIGNER for e in entries))
        self.assertEqual(len(set(entries)), 20)
        self.assertEqual(sorted(p.name for p in config.iterdir()), [".env", "signatures-pause.txt"])
        signatures = [e.split(":")[2] for e in entries]
        self.assertEqual(signatures, [f"{nonce:0128x}1b" for nonce in range(start, start + 20)])
        return signatures

    def test_transient_failure_retries_same_nonce_and_keeps_exact_batch(self):
        result = self.make(FAIL_NONCE="10")
        self.assertEqual(result.returncode, 0, result.stdout)
        signatures = self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10] + list(range(11, 27)))
        self.assertTrue(all(sig not in result.stdout for sig in signatures))
        self.assertIn("Send the contents of config/mainnet/signatures-pause.txt", result.stdout)
        self.assertFalse((self.task / "signatures-pause.txt").exists())
        self.assertFalse((self.task / "sign_output.tmp").exists())
        self.assertFalse((self.task / "unrelated-bin").exists())
        self.assertFalse((self.task / "gopath").exists())

    def test_interactive_retries_wait_for_enter_and_recover_same_nonce(self):
        locked = self.task / "ledger-locked"
        locked.touch()
        with self.interactive_make(LOCKED_NONCE="10") as (process, terminal):
            output = self.await_retry_prompt(process, 2)
            self.assertEqual(self.attempts(), [7, 8, 9, 10])
            os.write(terminal, b"\n")
            output += self.await_retry_prompt(process, 3)
            self.assertEqual(self.attempts(), [7, 8, 9, 10, 10])
            locked.unlink()
            os.write(terminal, b"\n")
            rest, _ = process.communicate(timeout=60)
            output += rest
            self.assertEqual(process.returncode, 0, output.decode())
        signatures = self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10] + list(range(10, 27)))
        self.assertTrue(all(sig.encode() not in output for sig in signatures))
        self.assertNotIn(b"Signature:", output)

    def assert_interactive_retry_abort(self, action):
        with self.interactive_make(FAIL_NONCE="10", FAIL_ALWAYS="1") as (process, terminal):
            output = self.await_retry_prompt(process, 2)
            if action == "eof":
                os.write(terminal, b"\x04")
            else:
                os.killpg(process.pid, signal.SIGINT)
            rest, _ = process.communicate(timeout=60)
            output += rest
            self.assertNotEqual(process.returncode, 0, output.decode())
        self.assertEqual(self.attempts(), [7, 8, 9, 10])
        config = self.task / "config/mainnet"
        self.assertFalse((config / "signatures-pause.txt").exists())
        self.assertFalse((config / ".pause-signing.lock").exists())
        state = config / ".pause-signing"
        self.assertEqual(sorted(p.name for p in state.iterdir()), ["0", "1", "2", "context"])
        for i in range(3):
            self.assertEqual((state / str(i)).read_text(), f"{SIGNER}:{7 + i}:{7 + i:0128x}1b\n")
        self.assertIn(b"Do not send partial signatures", output)
        self.assertIn(b"make TASK_NETWORK=mainnet sign-pause", output)
        self.assertNotIn(b"Signature:", output)
        resumed = self.make()
        self.assertEqual(resumed.returncode, 0, resumed.stdout)
        self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9, 10] + list(range(10, 27)))

    def test_interactive_retry_eof_stops_and_preserves_checkpoints(self):
        self.assert_interactive_retry_abort("eof")

    def test_interactive_retry_interrupt_stops_and_preserves_checkpoints(self):
        self.assert_interactive_retry_abort("interrupt")

    def test_bounded_failure_preserves_progress_and_rerun_resumes(self):
        failed = self.make(FAIL_NONCE="10", FAIL_ALWAYS="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10, 10])
        self.assertFalse((self.task / "config/mainnet/signatures-pause.txt").exists())
        self.assertIn("make TASK_NETWORK=mainnet sign-pause", failed.stdout)
        self.assertIn("Do not send partial signatures", failed.stdout)
        self.assertNotIn("Signature:", failed.stdout)
        checkpoint = self.task / "config/mainnet/.pause-signing/0"
        self.assertEqual(checkpoint.read_text(), f"{SIGNER}:7:{'0' * 127}71b\n")
        resumed = self.make()
        self.assertEqual(resumed.returncode, 0, resumed.stdout)
        self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10, 10] + list(range(10, 27)))

    def test_network_output_isolation_and_completed_batch_is_not_overwritten(self):
        self.assertEqual(self.make().returncode, 0)
        original = (self.task / "config/mainnet/signatures-pause.txt").read_bytes()
        other = self.make("sepolia", START_NONCE="50")
        self.assertEqual(other.returncode, 0, other.stdout)
        self.assert_batch("mainnet")
        self.assert_batch("sepolia", start=50)
        again = self.make()
        self.assertNotEqual(again.returncode, 0)
        self.assertEqual((self.task / "config/mainnet/signatures-pause.txt").read_bytes(), original)
        self.assertEqual(len(self.attempts()), 40)

    def test_concurrent_rerun_refuses_batch_completed_before_lock_acquisition(self):
        gates = {}
        for name in ("sign-ready", "sign-release", "lock-ready", "lock-release"):
            path = self.task / name
            os.mkfifo(path)
            gates[name] = os.open(path, os.O_RDWR | os.O_NONBLOCK)
            self.addCleanup(os.close, gates[name])

        processes = []

        def launch(**env):
            process = subprocess.Popen(
                ["make", "--no-print-directory", "TASK_NETWORK=mainnet", "sign-pause"],
                cwd=self.task, env=dict(self.env, **env), text=True,
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
            os.write(gates["sign-release"], b"go\n")
            first_output, _ = first.communicate(timeout=60)
            self.assertEqual(first.returncode, 0, first_output)
            output = self.task / "config/mainnet/signatures-pause.txt"
            original = output.read_bytes()
            os.write(gates["lock-release"], b"go\n")
            second_output, _ = second.communicate(timeout=60)
            self.assertNotEqual(second.returncode, 0, second_output)
            self.assertIn("already exists", second_output)
            self.assertEqual(output.read_bytes(), original)
            self.assertEqual(self.attempts(), list(range(7, 27)))
            self.assert_batch("mainnet")
        finally:
            for name in ("sign-release", "lock-release"):
                os.write(gates[name], b"go\n")
            for process in processes:
                process.communicate(timeout=60)

    def test_environment_only_network_is_rejected_before_signing(self):
        result = self.make(None, TASK_NETWORK="mainnet")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("command line", result.stdout)
        self.assertFalse((self.task / "attempts").exists())

    def test_changed_safe_nonce_cannot_mix_with_partial_batch(self):
        self.assertNotEqual(self.make(FAIL_NONCE="10", FAIL_ALWAYS="1").returncode, 0)
        before = self.attempts()
        changed = self.make(START_NONCE="8")
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("context changed", changed.stdout)
        self.assertEqual(self.attempts(), before)
        self.assertFalse((self.task / "config/mainnet/signatures-pause.txt").exists())

    def test_malformed_success_output_is_not_saved_as_a_signature(self):
        for malformed in ("duplicate", "truncated", "nonhex"):
            with self.subTest(malformed=malformed):
                failed = self.make(MALFORMED_NONCE="10", MALFORMED_OUTPUT=malformed)
                self.assertNotEqual(failed.returncode, 0, failed.stdout)
                self.assertNotIn("Signature:", failed.stdout)
                self.assertFalse((self.task / "config/mainnet/signatures-pause.txt").exists())
                self.assertFalse((self.task / "config/mainnet/.pause-signing/3").exists())
        resumed = self.make()
        self.assertEqual(resumed.returncode, 0, resumed.stdout)
        self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9] + [10] * 9 + list(range(10, 27)))


if __name__ == "__main__":
    unittest.main()
