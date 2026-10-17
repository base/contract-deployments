import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
OPERATION = "delay-upgrade-activation"
INVOCATION_DIRS = {"config", "records", "signatures", "status.json"}


def run(*args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)


def copy_canonical_task(source, target):
    shutil.copytree(source, target, ignore=lambda directory, names: INVOCATION_DIRS if Path(directory) == source else set())


class StandbyFixture(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.repo = Path(temp.name)
        for name in ("Makefile", "Multisig.mk", "scripts/Standby.mk", "scripts/standby-task.py",
                     "scripts/task-status.py", "scripts/task-status.schema.json", "active/evm/foundry.toml"):
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        self.task = self.repo / "standby/evm/tasks" / OPERATION
        copy_canonical_task(ROOT / "standby/evm/tasks" / OPERATION, self.task)
        self.env = dict(os.environ)
        for args in (("init", "-qb", "main"), ("add", "."),
                     ("-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"),
                     ("update-ref", "refs/remotes/origin/main", "HEAD")):
            result = run("git", *args, cwd=self.repo)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.repo / "config").mkdir()
        (self.repo / "config/local.env").write_text("L1_RPC_URL=http://127.0.0.1:1\nLEDGER_ACCOUNT=0\nPROTOCOL_VERSIONS_PROXY=0x0000000000000000000000000000000000001234\n")
        (self.config / ".env").write_text("BASE_CONTRACTS_COMMIT=385f21a41f277d287db92fffe88dca41299162ea\nUPGRADE_ID=0\nEXPECTED_CURRENT_TIMESTAMP=10000\nNEW_TIMESTAMP=20000\n")
        (self.config / "README.md").write_text("# Fixture delay\n\nStatus: READY TO SIGN\n")

    def make(self, target=None, network="local", *inputs):
        args = ["make"]
        if network is not None:
            args.append(f"TASK_NETWORK={network}")
        if target:
            args.append(target)
        return run(*args, *inputs, cwd=self.task, env=self.env)

    def snapshot(self):
        return {str(p.relative_to(self.task)): p.read_bytes() for p in self.task.rglob("*") if p.is_file()}

    def finalize(self, network="local", status="EXECUTED"):
        config = self.task / "config" / network
        config.mkdir(parents=True, exist_ok=True)
        (config / "README.md").write_text(f"# Fixture\n\nStatus: {status}\n")
        (config / "validations").mkdir(exist_ok=True)
        (config / "validations/base-signer.json").write_text('{"cmd":"exit 91","final":true}\n')
        (config / "addresses.json").write_text('{"fixture":"address"}\n')
        if network != "local":
            shutil.copy2(self.repo / "config/local.env", self.repo / "config" / f"{network}.env")
        signatures = self.task / "signatures" / network
        signatures.mkdir(parents=True, exist_ok=True)
        (signatures / "bundle.json").write_text("signature artifact\n")
        records = self.task / "records/DelayUpgradeActivation.s.sol/31337"
        records.mkdir(parents=True, exist_ok=True)
        (records / "run-final.json").write_text("final record\n")
        path = self.task / "status.json"
        data = json.loads(path.read_text()) if path.exists() else {
            "schema_version": 1, "task": self.task.name, "kind": "standby",
            "last_updated": "2026-10-20T00:00:00Z", "networks": {},
        }
        executed = "EXECUTED" in status
        data["networks"][network] = {
            "step": "executed" if executed else "canceled", "pr": None, "blocksec_ticket": None,
            "signatures": {}, "executed_tx": "0x" + "ab" * 32 if executed else None,
        }
        path.write_text(json.dumps(data) + "\n")


class StandbyLifecycle(StandbyFixture):
    def test_verifier_canonical_has_no_invocation_data(self):
        task = ROOT / "standby/evm/tasks/update-verifier-hashes"
        self.assertTrue(task.is_dir(), "canonical verifier standby operation is missing")
        self.assertTrue((task / "Makefile").is_file())
        self.assertTrue((task / "FACILITATOR.md").is_file())
        self.assertTrue(all(not (task / name).exists() for name in INVOCATION_DIRS))
        self.assertFalse(any(path.suffix == ".json" or path.name == ".env" for path in task.rglob("*")))

    def test_verifier_archive_preserves_canonical_bytes(self):
        source = ROOT / "standby/evm/tasks/update-verifier-hashes"
        self.assertTrue(source.is_dir(), "canonical verifier standby operation is missing")
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(source, self.task)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.config / ".env").write_text(
            "BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962\nGAME_TYPE=42\n"
            "CURRENT_AGGREGATE_VERIFIER=0x0000000000000000000000000000000000001111\n"
            + "".join(f"AGGREGATE_VERIFIER_{key}_HASH=0x{value:064x}\n" for key, value in (("TEE_IMAGE", 4), ("ZK_RANGE", 5), ("ZK_AGGREGATE", 6)))
        )
        result = run("git", "add", ".", cwd=self.repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = run("git", "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "canonical verifier", cwd=self.repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        run("git", "update-ref", "refs/remotes/origin/main", "HEAD", cwd=self.repo)
        self.finalize()
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-14")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        archive = self.repo / "archive/evm/2026-10-14-update-verifier-hashes"
        self.assertEqual(self.snapshot(), {name: data for name, data in before.items() if name.split("/")[0] not in INVOCATION_DIRS})
        for name, data in before.items():
            self.assertEqual((archive / name).read_bytes(), data, name)

    def test_default_goal_prepares_without_archiving(self):
        self.finalize()
        before = self.snapshot()
        result = self.make(None, "local", "TASK_DATE=2026-10-13")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        self.assertFalse((self.repo / "archive").exists())

    def test_every_command_requires_command_line_network(self):
        self.env["TASK_NETWORK"] = "local"
        for target in ("prepare", "gen-validation-cb", "sign-task", "execute", "verify", "archive-task", "bootstrap-mise"):
            with self.subTest(target=target):
                result = self.make(target, None)
                self.assertNotEqual(result.returncode, 0)
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
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn("network.env is reserved for the archive snapshot", result.stderr)
                    self.assertEqual(self.snapshot(), before)
            result = run("python3", str(self.repo / "scripts/standby-task.py"), "check-delay", "--repo", str(self.repo), "--task", str(self.task), "--network", network, cwd=self.repo)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("network.env is reserved for the archive snapshot", result.stderr)
            self.assertEqual(self.snapshot(), before)
            reserved.unlink()

    def test_archive_is_lossless_and_canonical_unchanged(self):
        self.finalize(status="[EXECUTED](https://example.invalid/tx/fixture)")
        self.finalize("other", "CANCELED https://example.invalid/incident/fixture")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        archived = self.repo / "archive/evm/2026-10-13-delay-upgrade-activation"
        for name, data in before.items():
            self.assertEqual((archived / name).read_bytes(), data, name)
        canonical = {name: data for name, data in before.items() if name.split("/")[0] not in INVOCATION_DIRS}
        self.assertEqual(self.snapshot(), canonical)
        for name in INVOCATION_DIRS:
            self.assertFalse(os.path.lexists(self.task / name))
        self.assertEqual((archived / "foundry.toml").read_bytes(), (self.repo / "active/evm/foundry.toml").read_bytes())
        for network in ("local", "other"):
            self.assertEqual((archived / "config" / network / "network.env").read_bytes(), (self.repo / "config" / f"{network}.env").read_bytes())
        self.task = archived
        before = self.snapshot()
        result = self.make("execute", "local", "-n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("network.env is reserved for the archive snapshot", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_verifier_every_command_requires_command_line_network(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        self.env["TASK_NETWORK"] = "local"
        for target in ("prepare", "deps", "build", "deploy", "verify", "validate", "gen-validation-cb", "gen-validation-sc", "approve-cb", "approve-sc", "execute", "post-check", "archive-task", "sign-task", "bootstrap-mise"):
            with self.subTest(target=target):
                result = self.make(target, None)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("command line", result.stderr)

    def test_verifier_origin_is_skipped_only_outside_mainnet(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        for network in ("local", "mainnet"):
            config = self.task / "config" / network
            config.mkdir(parents=True)
            (config / ".env").write_text("BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962\n")
            if network != "local":
                shutil.copy2(self.repo / "config/local.env", self.repo / "config" / f"{network}.env")
            for target in ("gen-validation-cb", "gen-validation-sc"):
                result = self.make(target, network, "-n", "CB_SENDER=0x0000000000000000000000000000000000009999", "SC_SENDER=0x0000000000000000000000000000000000009999", "NEW_AGGREGATE_VERIFIER=0x0000000000000000000000000000000000002222")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual("skip-origin" in result.stdout, network != "mainnet")

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
        self.assertFalse((self.repo / "archive").exists())

    def test_archive_rejects_invalid_or_pending_status_without_changes(self):
        self.finalize()
        path = self.task / "status.json"
        finalized = path.read_text()
        cases = [("invalid JSON", "{", "status.json"), ("missing", None, "missing status.json")]
        for field, value in (("schema_version", 2), ("kind", "active"), ("task", "wrong"),
                             ("networks", {"other": json.loads(finalized)["networks"]["local"]})):
            data = json.loads(finalized)
            data[field] = value
            cases.append((field, json.dumps(data), field))
        for step, tx, readme, message in (
            ("authoring", None, "EXECUTED", "finalized Status"),
            ("executed", None, "EXECUTED", "executed_tx"),
            ("canceled", None, "EXECUTED", "finalized Status"),
            ("authoring", None, "READY TO SIGN", "not finalized"),
        ):
            data = json.loads(finalized)
            data["networks"]["local"].update(step=step, executed_tx=tx)
            cases.append((readme, json.dumps(data), message))
        for readme, content, message in cases:
            with self.subTest(status=readme, content=content):
                (self.config / "README.md").write_text(f"Status: {readme}\n")
                if content is None:
                    path.unlink()
                else:
                    path.write_text(content)
                before = self.snapshot()
                result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.snapshot(), before)
                self.assertFalse((self.repo / "archive").exists())

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

    def test_archive_requires_one_authoritative_final_status(self):
        self.finalize()
        for status in ("READY TO SIGN\n\nOld incident\nStatus: EXECUTED", "", "EXECUTED\nStatus: CANCELED"):
            with self.subTest(status=status):
                (self.config / "README.md").write_text(f"# Fixture\n\nStatus: {status}\n")
                before = self.snapshot()
                result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("not finalized", result.stdout + result.stderr)
                self.assertEqual(self.snapshot(), before)

    def test_archive_refuses_drift_overwrites_bad_dates_and_paths(self):
        self.finalize()
        guide = self.task / "FACILITATOR.md"
        original = guide.read_bytes()
        guide.write_bytes(original + b"changed\n")
        before = self.snapshot()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("differ from main", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        guide.write_bytes(original)
        before = self.snapshot()
        destination = self.repo / "archive/evm/2026-10-13-delay-upgrade-activation"
        destination.mkdir(parents=True)
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already exists", result.stdout + result.stderr)
        for value in ("2026-02-30", "../escape", "20261013"):
            with self.subTest(date=value):
                result = self.make("archive-task", "local", f"TASK_DATE={value}")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("invalid", result.stdout + result.stderr)
        result = self.make("prepare", "../escape")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid", result.stdout + result.stderr)
        result = run("python3", str(self.repo / "scripts/standby-task.py"), "archive", "--repo", str(self.repo / "elsewhere"), "--task", str(self.task), "--network", "local", "--date", "2026-10-14", cwd=self.repo)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be a canonical standby task", result.stderr)
        link = self.config / "linked-signatures"
        link.symlink_to(self.task / "signatures/local/bundle.json")
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-14")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink not allowed", result.stderr)
        link.unlink()
        self.assertEqual(self.snapshot(), before)
        self.assertEqual(list(destination.iterdir()), [])

    def test_operational_checkout_artifacts_are_not_inherited_or_touched(self):
        self.finalize()
        source = self.repo / "operational-checkout"
        artifacts = {name: data for name, data in self.snapshot().items() if name.split("/")[0] in INVOCATION_DIRS}
        self.task.rename(source)
        for name in artifacts:
            (source / name).chmod(0)
        copy_canonical_task(source, self.task)
        self.assertTrue(all(name.split("/")[0] not in INVOCATION_DIRS for name in self.snapshot()))
        self.config.mkdir(parents=True)
        (self.config / ".env").write_bytes(artifacts["config/local/.env"])
        (self.config / "README.md").write_text("Status: READY TO SIGN\n")
        result = self.make("prepare")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.finalize()
        result = self.make("archive-task", "local", "TASK_DATE=2026-10-13")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for name, data in artifacts.items():
            path = source / name
            self.assertEqual(path.stat().st_mode & 0o777, 0)
            path.chmod(0o600)
            self.assertEqual(path.read_bytes(), data, name)


class VerifierConfig(StandbyFixture):
    def setUp(self):
        super().setUp()
        self.values = {
            "BASE_CONTRACTS_COMMIT": "8c21f6d08a36b4059ae2bb8938f1e7e758a0e962",
            "GAME_TYPE": "42",
            "CURRENT_AGGREGATE_VERIFIER": "0x" + "12" * 20,
            "AGGREGATE_VERIFIER_TEE_IMAGE_HASH": "0x" + "34" * 32,
            "AGGREGATE_VERIFIER_ZK_RANGE_HASH": "0x" + "56" * 32,
            "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH": "0x" + "78" * 32,
        }

    def check(self):
        (self.config / ".env").write_text("".join(f"{key}={value}\n" for key, value in self.values.items()))
        return run("python3", str(self.repo / "scripts/standby-task.py"), "check-verifier", "--repo", str(self.repo), "--task", str(self.task), "--network", "local", cwd=self.repo)

    def test_supported_inputs(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_verifier_deps_rejects_invalid_pin_without_touching_lib(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.config / "README.md").write_text("Status: READY TO SIGN\n")
        self.values["BASE_CONTRACTS_COMMIT"] = "38" * 20
        (self.config / ".env").write_text("".join(f"{key}={value}\n" for key, value in self.values.items()))
        overrides = self.repo / "offline.mk"
        overrides.write_text("bootstrap-mise install-eip712sign: ; @true\n")
        stub = self.repo / "offline-install.sh"
        stub.write_text("#!/bin/sh\nmkdir -p lib\nprintf 'fixture dependency\\n' > lib/installed\n")
        for jobs in ("-j1", "-j4"):
            with self.subTest(jobs=jobs):
                project = self.repo / f"project{jobs}"
                lib = project / "lib"
                lib.mkdir(parents=True)
                sentinel = lib / "existing"
                sentinel.write_bytes(b"shared dependency\n")
                before = {path: path.stat() for path in (lib, sentinel)}
                result = self.make(
                    "deps", "local", jobs, "-f", "Makefile", "-f", str(overrides),
                    f"PROJECT_DIR={project}", f"MISE_EXEC=sh {stub}", f"GOPATH={self.repo / 'gopath'}",
                )
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("unsupported BASE_CONTRACTS_COMMIT", result.stderr)
                self.assertEqual(list(lib.iterdir()), [sentinel])
                self.assertEqual(sentinel.read_bytes(), b"shared dependency\n")
                for path, original in before.items():
                    current = path.stat()
                    self.assertEqual(
                        (current.st_ino, current.st_mtime_ns, current.st_ctime_ns),
                        (original.st_ino, original.st_mtime_ns, original.st_ctime_ns),
                    )

    def test_verifier_parallel_deps_installs_after_cleaning_lib(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.config / "README.md").write_text("Status: READY TO SIGN\n")
        (self.config / ".env").write_text("".join(f"{key}={value}\n" for key, value in self.values.items()))
        project = self.repo / "project"
        (project / "lib").mkdir(parents=True)
        (project / "lib/stale").write_bytes(b"old dependency\n")
        overrides = self.repo / "offline.mk"
        overrides.write_text(
            "bootstrap-mise install-eip712sign: ; @true\n"
            "clean-lib:\n\tsleep 1; rm -rf $(PROJECT_DIR)/lib\n"
        )
        stub = self.repo / "offline-install.sh"
        stub.write_text("#!/bin/sh\nmkdir -p lib\nprintf 'fixture dependency\\n' > lib/installed\n")
        result = self.make(
            "deps", "local", "-j4", "-f", "Makefile", "-f", str(overrides),
            f"PROJECT_DIR={project}", f"MISE_EXEC=sh {stub}", f"GOPATH={self.repo / 'gopath'}",
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(sorted(path.name for path in (project / "lib").iterdir()), ["installed"])

    def test_rejects_unsupported_pin_formats_and_zero_values(self):
        for key, value in (
            ("BASE_CONTRACTS_COMMIT", "38" * 20), ("GAME_TYPE", str(2**32)),
            ("GAME_TYPE", "-1"), ("GAME_TYPE", "0x2a"),
            ("CURRENT_AGGREGATE_VERIFIER", "0x" + "00" * 20),
            ("CURRENT_AGGREGATE_VERIFIER", "0x1234"),
            ("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", "0x" + "00" * 32),
            ("AGGREGATE_VERIFIER_ZK_RANGE_HASH", "0x1234"),
            ("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", "xyz"),
        ):
            with self.subTest(key=key, value=value):
                original = self.values[key]
                self.values[key] = value
                result = self.check()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(key, result.stderr)
                self.values[key] = original

    def test_rejects_record_state_diff_and_missing_readme(self):
        self.values["RECORD_STATE_DIFF"] = "true"
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("injected by the signer tool", result.stderr)
        del self.values["RECORD_STATE_DIFF"]
        (self.config / "README.md").unlink()
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing signer README", result.stderr)


class VerifierArtifacts(StandbyFixture):
    def test_make_artifacts_use_only_selected_invocation_permissions(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.config / "README.md").write_text("Status: READY TO SIGN\n")
        (self.config / ".env").write_text(
            "BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962\nGAME_TYPE=42\n"
            "CURRENT_AGGREGATE_VERIFIER=0x0000000000000000000000000000000000001111\n"
            + "".join(f"AGGREGATE_VERIFIER_{key}_HASH=0x{value:064x}\n" for key, value in (("TEE_IMAGE", 4), ("ZK_RANGE", 5), ("ZK_AGGREGATE", 6)))
        )
        project = self.repo / "active/evm"
        (project / "script").mkdir()
        shutil.copy2(ROOT / "scripts/tests/StandbyArtifacts.s.sol", project / "script/UpdateVerifierHashes.s.sol")
        forge = run("mise", "-C", str(ROOT), "which", "forge", cwd=ROOT)
        self.assertEqual(forge.returncode, 0, forge.stderr)
        self.env["PINNED_FORGE"] = forge.stdout.strip()
        wrapper = self.repo / "offline-forge.py"
        wrapper.write_text(
            "import os, subprocess, sys\n"
            "args = iter(sys.argv[1:])\n"
            "assert next(args) == 'forge'\n"
            "assert next(args) == 'script'\n"
            "command = [os.environ['PINNED_FORGE'], 'script']\n"
            "for arg in args:\n"
            "    if arg in ('--rpc-url', '--hd-paths'):\n"
            "        next(args)\n"
            "    elif arg not in ('--ledger', '--broadcast'):\n"
            "        command.append(arg)\n"
            "sys.exit(subprocess.run(command).returncode)\n"
        )
        overrides = self.repo / "offline.mk"
        overrides.write_text("bootstrap-mise: ; @true\n")
        options = (
            "-f", "Makefile", "-f", str(overrides), f"MISE_EXEC=python3 {wrapper}",
            "SCRIPT_DIR=script", "DEPLOY_SCRIPT=script/UpdateVerifierHashes.s.sol:DeployAggregateVerifier",
        )
        for target in ("deploy", "validate", "post-check"):
            with self.subTest(target=target):
                result = self.make(target, "local", *options, "WITH_ARTIFACT_PERMISSIONS=cd $(PROJECT_DIR) && $(1)")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("not allowed to be accessed", result.stdout + result.stderr)
                result = self.make(target, "local", *options)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(list(project.glob(".verifier-foundry-*")))
        for directory in (self.task, self.task / "config/other"):
            directory.mkdir(exist_ok=True)
            with self.subTest(denied=directory):
                result = self.make("validate", "local", *options, f"PRESTATE_JSON={directory}/prestate.json")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("not allowed to be accessed", result.stdout + result.stderr)
                self.assertFalse((directory / "prestate.json").exists())
                self.assertFalse(list(project.glob(".verifier-foundry-*")))


if __name__ == "__main__":
    unittest.main()
