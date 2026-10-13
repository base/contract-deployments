from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import shlex
import threading
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
OPERATION = "delay-upgrade-activation"
INVOCATION_DIRS = {"config", "records", "signatures"}


def run(*args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)


def copy_canonical_task(source, target):
    shutil.copytree(source, target, ignore=lambda directory, names: INVOCATION_DIRS if Path(directory) == source else set())


class FixtureRPC(BaseHTTPRequestHandler):
    def do_POST(self):
        request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        response = {"jsonrpc": "2.0", "id": request["id"], "result": "0x7a69"}
        if request["method"] != "eth_chainId":
            response = {"jsonrpc": "2.0", "id": request["id"], "error": {"code": -32601, "message": "fixture supports chain ID only"}}
        encoded = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, *args):
        return


class StandbyLifecycle(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        for name in ("Makefile", "Multisig.mk", "scripts", "config", "active/evm/foundry.toml"):
            source = ROOT / name
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if source.is_dir():
                shutil.copytree(source, target, ignore=shutil.ignore_patterns("__pycache__"))
            else:
                shutil.copy2(source, target)
        canonical = ROOT / "standby/evm/tasks" / OPERATION
        self.assertTrue(canonical.is_dir(), f"missing canonical standby operation: {canonical}")
        self.task = self.repo / "standby/evm/tasks" / OPERATION
        copy_canonical_task(canonical, self.task)
        (self.repo / "active/evm/tasks").mkdir(parents=True)
        run("git", "init", "-b", "main", cwd=self.repo)
        run("git", "add", ".", cwd=self.repo)
        result = run("git", "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture", cwd=self.repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        run("git", "update-ref", "refs/remotes/origin/main", "HEAD", cwd=self.repo)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        rpc = ThreadingHTTPServer(("127.0.0.1", 0), FixtureRPC)
        self.addCleanup(rpc.server_close)
        self.addCleanup(rpc.shutdown)
        threading.Thread(target=rpc.serve_forever, daemon=True).start()
        (self.repo / "config/local.env").write_text(f"L1_RPC_URL=http://127.0.0.1:{rpc.server_port}\nLEDGER_ACCOUNT=0\nPROTOCOL_VERSIONS_PROXY=0x0000000000000000000000000000000000001234\n")
        (self.config / ".env").write_text("BASE_CONTRACTS_COMMIT=385f21a41f277d287db92fffe88dca41299162ea\nUPGRADE_ID=0\nEXPECTED_CURRENT_TIMESTAMP=10000\nNEW_TIMESTAMP=20000\n")
        (self.config / "README.md").write_text("# Fixture delay\n\nStatus: READY TO SIGN\n")
        self.bin = self.repo / "bin"
        self.bin.mkdir()
        for tool in ("mise", "ottr-cli"):
            stub = self.bin / tool
            stub.write_text(f'#!/bin/sh\nexec python3 "$SOURCE_ROOT/scripts/tests/credential-stubs.py" {tool} "$@"\n')
            stub.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", ORIGINAL_PATH=os.environ["PATH"], ORIGINAL_HOME=os.environ["HOME"], FIXTURE_HOME=str(self.repo / "home"), SOURCE_ROOT=str(ROOT), SIGNER_SMOKE_MARKER=str(self.repo / "opened"))
        (self.repo / "signer-tool").mkdir()
        # Replaces credential/network bootstrap only. Task recipes and global macros stay real.
        self.overrides = self.repo / "offline.mk"
        self.overrides.write_text(".PHONY: bootstrap-mise checkout-signer-tool deps-signer-tool\nbootstrap-mise checkout-signer-tool deps-signer-tool: ; @true\n")

    def make(self, target, network="local", *inputs):
        args = ["make", "-f", "Makefile", "-f", str(self.overrides)]
        if network is not None:
            args.append(f"TASK_NETWORK={network}")
        return run(*args, target, *inputs, cwd=self.task, env=self.env)

    def snapshot(self):
        return {str(p.relative_to(self.task)): p.read_bytes() for p in self.task.rglob("*") if p.is_file()}

    def finalize(self, network="local", status="EXECUTED"):
        config = self.task / "config" / network
        config.mkdir(parents=True, exist_ok=True)
        (config / "README.md").write_text(f"# Fixture\n\nStatus: {status}\n")
        (config / "validations").mkdir(exist_ok=True)
        (config / "validations/base-signer.json").write_text('{"final":true}\n')
        (config / "addresses.json").write_text('{"fixture":"address"}\n')
        if not (self.repo / "config" / f"{network}.env").exists():
            shutil.copy2(self.repo / "config/local.env", self.repo / "config" / f"{network}.env")
        signatures = self.task / "signatures" / network
        signatures.mkdir(parents=True, exist_ok=True)
        (signatures / "bundle.json").write_text("signature artifact\n")
        records = self.task / "records/DelayUpgradeActivation.s.sol/31337"
        records.mkdir(parents=True, exist_ok=True)
        (records / "run-final.json").write_text("final record\n")

    def test_default_goal_prepares_without_archiving(self):
        self.finalize()
        result = run("make", "-f", "Makefile", "-f", str(self.overrides), "TASK_NETWORK=local", "TASK_DATE=2026-10-13", cwd=self.task, env=self.env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.config.is_dir(), "default Make invocation must never archive an operation")

    def test_prepare_validation_and_sign_paths(self):
        result = self.make("prepare")
        self.assertEqual(result.returncode, 0, f"prepare must accept config-only invocation: {result.stdout}{result.stderr}")
        result = self.make("gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        validation = self.config / "validations/base-signer.json"
        self.assertTrue(validation.is_file(), "validation must belong to selected network")
        import json
        content = json.loads(validation.read_text())
        self.assertTrue(content["skipTaskOriginValidation"])
        tokens = shlex.split(content["cmd"])
        self.assertEqual(tokens[tokens.index("--sig") + 1:tokens.index("--sig") + 3], ["sign(address[])", "[]"])
        self.assertIn("UPGRADE_ID=0", content["cmd"])
        self.assertNotIn("SECURITY_COUNCIL", content["cmd"])
        self.assertNotIn("RECORD_STATE_DIFF", (self.config / ".env").read_text())
        self.assertEqual(self.make("sign-task").returncode, 0)
        self.assertEqual((self.repo / "opened").read_text(), "opened")

    @unittest.skipUnless(os.environ.get("STANDBY_SOLIDITY_INTEGRATION") == "1", "requires installed Foundry fixture dependencies")
    def test_config_only_validation_contains_real_fixture_calldata(self):
        result = self.make("gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        import json
        validation = json.loads((self.config / "validations/base-signer.json").read_text())
        artifact = self.config / "validations/.call-fixture.json"
        call = json.loads(artifact.read_text()) if artifact.exists() else validation
        self.assertIn("calldata", call, "credential stub must preserve real task-built calldata")
        expected = run("mise", "exec", "--", "cast", "calldata", "delayTimestamp(uint256,uint64)", "0", "20000", cwd=ROOT)
        self.assertEqual(expected.returncode, 0, expected.stderr)
        self.assertEqual(call["calldata"], expected.stdout.strip())
        self.assertEqual(call["count"], 1)
        self.assertEqual(call["target"].lower(), "0x0000000000000000000000000000000000001234")
        self.assertEqual(call["safe"].lower(), "0x000000000000000000000000000000000000beef")
        self.assertEqual(call["operation"], 0)
        self.assertEqual(call["value"], 0)
        self.assertTrue(validation["skipTaskOriginValidation"])

    @unittest.skipUnless(os.environ.get("STANDBY_SIGNER_HOME"), "requires the pinned signer checkout")
    def test_actual_signer_generates_base_only_validation(self):
        result = self.make("gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        import json
        validation = json.loads((self.config / "validations/base-signer.json").read_text())
        self.assertIn("rpcUrl", validation, "validation must come from the real signer generator")
        self.assertEqual(validation["expectedDomainAndMessageHashes"]["address"].lower(), "0x000000000000000000000000000000000000beef")
        self.assertEqual([entry["address"].lower() for entry in validation["stateOverrides"]], ["0x000000000000000000000000000000000000beef"])
        self.assertTrue(any(entry["address"].lower() == "0x0000000000000000000000000000000000001234" for entry in validation["stateChanges"]))
        self.assertTrue(validation["skipTaskOriginValidation"])

    def test_every_command_requires_command_line_network(self):
        self.env["TASK_NETWORK"] = "local"
        for target in ("prepare", "gen-validation-cb", "sign-task", "execute", "verify", "archive-task", "bootstrap-mise"):
            with self.subTest(target=target):
                result = self.make(target, None)
                self.assertNotEqual(result.returncode, 0, "exported TASK_NETWORK must not select an invocation")
                self.assertIn("command line", result.stderr)

    def test_reserved_network_snapshot_is_rejected_without_changes(self):
        for network in ("local", "other"):
            config = self.task / "config" / network
            config.mkdir(exist_ok=True)
            reserved = config / "network.env"
            reserved.write_bytes((self.repo / "config/local.env").read_bytes())
            before = self.snapshot()
            for target in ("prepare", "build", "validate", "gen-validation-cb", "execute", "verify", "deps"):
                with self.subTest(network=network, target=target):
                    result = self.make(target, "local", *([] if target == "prepare" else ["-n"]))
                    self.assertEqual(self.snapshot(), before)
                    self.assertNotEqual(result.returncode, 0, f"{target} accepted reserved {reserved}: {result.stdout}{result.stderr}")
                    self.assertIn("network.env is reserved for the archive snapshot", result.stderr)
            if network == "local":
                with self.subTest(command="check-delay"):
                    result = run("python3", str(self.repo / "scripts/standby-task.py"), "check-delay", "--repo", str(self.repo), "--task", str(self.task), "--network", network, cwd=self.repo)
                    self.assertEqual(self.snapshot(), before)
                    self.assertNotEqual(result.returncode, 0, "check-delay accepted reserved network.env")
                    self.assertIn("network.env is reserved for the archive snapshot", result.stderr)
            reserved.unlink()

    def test_archive_is_lossless_and_canonical_unchanged(self):
        self.finalize()
        self.finalize("other", "CANCELED")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertEqual(result.returncode, 0, f"archive must preserve finalized invocation: {result.stdout}{result.stderr}")
        archived = self.repo / "archive/evm/2026-10-13-delay-upgrade-activation"
        for name, data in before.items():
            self.assertEqual((archived / name).read_bytes(), data, name)
        canonical = {name: data for name, data in before.items() if not name.startswith(("config/", "records/", "signatures/"))}
        self.assertEqual(self.snapshot(), canonical)
        for name in INVOCATION_DIRS:
            self.assertFalse(os.path.lexists(self.task / name), f"archive left invocation data in standby: {name}")
        self.assertTrue((archived / "foundry.toml").is_file())
        for network in ("local", "other"):
            self.assertEqual((archived / "config" / network / "network.env").read_bytes(), (self.repo / "config" / f"{network}.env").read_bytes())
        self.task = archived
        before = self.snapshot()
        result = self.make("execute", "local", "-n")
        self.assertEqual(self.snapshot(), before)
        self.assertNotEqual(result.returncode, 0, "archive snapshots must not become executable tasks")
        self.assertIn("network.env is reserved for the archive snapshot", result.stderr)

    def test_archive_refuses_pending_other_network_without_data_loss(self):
        self.finalize()
        pending = self.task / "config/other"
        pending.mkdir()
        (pending / "README.md").write_text("Status: READY TO SIGN\n")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not finalized", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_archive_rejects_dated_operation_identifier_without_data_loss(self):
        self.finalize()
        renamed = self.task.with_name("2026-10-13-delay-upgrade-activation")
        self.task.rename(renamed)
        self.task = renamed
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid task identifier", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_archive_uses_authoritative_status_and_accepts_execution_links(self):
        self.finalize()
        readme = self.config / "README.md"
        readme.write_text("# Fixture\n\nStatus: READY TO SIGN\n\nOld incident\nStatus: EXECUTED\n")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0, "an execution mention must not finalize a pending invocation")
        self.assertEqual(self.snapshot(), before)
        readme.write_text("# Fixture\n\nStatus: [EXECUTED](https://example.invalid/tx/fixture)\n")
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-14")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_archive_refuses_modified_canonical_overwrites_and_bad_identifiers(self):
        self.finalize()
        guide = self.task / "FACILITATOR.md"
        guide.write_text(guide.read_text() + "changed\n")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("differ from main", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        guide.write_bytes(run("git", "show", f"HEAD:standby/evm/tasks/{OPERATION}/FACILITATOR.md", cwd=self.repo).stdout.encode())
        destination = self.repo / "archive/evm/2026-10-13-delay-upgrade-activation"
        destination.mkdir(parents=True)
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertIn("already exists", result.stdout + result.stderr)
        for value in ("2026-02-30", "../escape", "20261013"):
            result = self.make("archive-task", "local", f"TASK_DATE={value}")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("invalid", result.stdout + result.stderr)
        result = self.make("prepare", "../escape")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid", result.stdout + result.stderr)


class CanonicalStandby(unittest.TestCase):
    def test_canonical_files_have_no_invocation_artifacts(self):
        task = ROOT / "standby/evm/tasks" / OPERATION
        self.assertTrue(task.is_dir())
        # Operational branches carry invocations; archival removes them before merge.
        for directory, dirs, files in os.walk(task):
            if Path(directory) == task:
                dirs[:] = [name for name in dirs if name not in INVOCATION_DIRS]
            for name in dirs + files:
                self.assertNotIn(name, INVOCATION_DIRS | {"validations", "addresses.json", ".env"}, str(Path(directory) / name))

    def test_committed_invocation_does_not_break_canonical_or_archive_tests(self):
        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory)
            for name in ("Makefile", "Multisig.mk", "scripts", "config", "active/evm/foundry.toml"):
                source = ROOT / name
                target = checkout / name
                target.parent.mkdir(parents=True, exist_ok=True)
                if source.is_dir():
                    shutil.copytree(source, target, ignore=shutil.ignore_patterns("__pycache__"))
                else:
                    shutil.copy2(source, target)
            task = checkout / "standby/evm/tasks" / OPERATION
            copy_canonical_task(ROOT / "standby/evm/tasks" / OPERATION, task)
            artifacts = {
                "config/fixture/.env": b"BASE_CONTRACTS_COMMIT=385f21a41f277d287db92fffe88dca41299162ea\nUPGRADE_ID=0\nEXPECTED_CURRENT_TIMESTAMP=10000\nNEW_TIMESTAMP=20000\n",
                "config/fixture/README.md": b"Status: READY TO SIGN\n",
                "config/fixture/addresses.json": b'{"fixture":"address"}\n',
                "config/fixture/validations/base-signer.json": b'{"cmd":"exit 91"}\n',
                "signatures/fixture/bundle.json": b'{"signature":"0xfeed","fixture":true}\n',
                "records/DelayUpgradeActivation.s.sol/31337/run-final.json": b'{"fixture":true}\n',
            }
            for name, data in artifacts.items():
                path = task / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            run("git", "init", "-b", "invocation", cwd=checkout)
            run("git", "add", ".", cwd=checkout)
            committed = run("git", "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "invocation fixture", cwd=checkout)
            self.assertEqual(committed.returncode, 0, committed.stderr)
            result = run(sys.executable, "-B", "-m", "unittest",
                         "scripts.tests.test_standby_lifecycle.CanonicalStandby.test_canonical_files_have_no_invocation_artifacts",
                         "scripts.tests.test_standby_lifecycle.StandbyLifecycle.test_archive_is_lossless_and_canonical_unchanged",
                         cwd=checkout)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual({name: (task / name).read_bytes() for name in artifacts}, artifacts)
            self.assertEqual(run("git", "status", "--porcelain", cwd=checkout).stdout, "")


if __name__ == "__main__":
    unittest.main()
