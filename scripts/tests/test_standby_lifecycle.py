import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
OPERATION = "delay-upgrade-activation"
INVOCATION_DIRS = {"config", "records", "signatures"}


def run(*args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)


def copy_canonical_task(source, target):
    shutil.copytree(source, target, ignore=lambda directory, names: INVOCATION_DIRS if Path(directory) == source else set())


class StandbyFixture(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.repo = Path(temp.name)
        for name in ("Makefile", "Multisig.mk", "scripts/Standby.mk", "scripts/standby-task.py", "active/evm/foundry.toml"):
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


class StandbyLifecycle(StandbyFixture):
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


if __name__ == "__main__":
    unittest.main()
