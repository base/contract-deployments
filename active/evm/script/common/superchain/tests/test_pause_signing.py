import os
from pathlib import Path
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
    eip712sign)
        data=${!#}
        nonce=$((16#${data: -8}))
        previous=false
        if [[ -f $FIXTURE/attempts ]] && grep -qx "$nonce" "$FIXTURE/attempts"; then previous=true; fi
        echo "$nonce" >> "$FIXTURE/attempts"
        printf -v signature '0x%0128x1b' "$nonce"
        echo 'Signer: 0xabababababababababababababababababababab'
        echo "Signature: $signature"
        echo "Signature: $signature" >&2
        if [[ ${FAIL_NONCE:-} == "$nonce" && ( ${FAIL_ALWAYS:-} || $previous == false ) ]]; then exit 1; fi
        if [[ ${MALFORMED_NONCE:-} == "$nonce" ]]; then echo 'Signature: malformed'; fi
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
        for tool in ("mise", "go", "cast"):
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
                        GOBIN=str(self.task / "unrelated-bin"))

    def make(self, network="mainnet", **env):
        args = ["make", "--no-print-directory"]
        if network is not None:
            args.append(f"TASK_NETWORK={network}")
        return subprocess.run(args + ["sign-pause"], cwd=self.task,
                              env=dict(self.env, **env), text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              timeout=60)

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
        return [e.split(":")[2] for e in entries]

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

    def test_bounded_failure_preserves_progress_and_rerun_resumes(self):
        failed = self.make(FAIL_NONCE="10", FAIL_ALWAYS="1")
        self.assertNotEqual(failed.returncode, 0)
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10, 10])
        self.assertFalse((self.task / "config/mainnet/signatures-pause.txt").exists())
        self.assertIn("make TASK_NETWORK=mainnet sign-pause", failed.stdout)
        self.assertIn("Do not send partial signatures", failed.stdout)
        self.assertNotIn("Signature:", failed.stdout)
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
        failed = self.make(MALFORMED_NONCE="10")
        self.assertNotEqual(failed.returncode, 0)
        self.assertFalse((self.task / "config/mainnet/signatures-pause.txt").exists())
        resumed = self.make()
        self.assertEqual(resumed.returncode, 0, resumed.stdout)
        self.assert_batch("mainnet")
        self.assertEqual(self.attempts(), [7, 8, 9, 10, 10, 10] + list(range(10, 27)))


if __name__ == "__main__":
    unittest.main()
