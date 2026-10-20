import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from scripts.tests.test_standby_lifecycle import copy_canonical_task

ROOT = Path(__file__).resolve().parents[2]
TASK = "2026-10-20-example"
TX = "0x" + "ab" * 32


def run(*args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)


def status(task=TASK, kind="active"):
    return {
        "schema_version": 1, "task": task, "kind": kind,
        "last_updated": "2026-10-20T00:00:00Z",
        "networks": {"local": {
            "step": "authoring", "pr": None, "blocksec_ticket": None,
            "signatures": {}, "executed_tx": None,
        }},
    }


class TaskFixture(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.repo = Path(temp.name)
        for name in ("Makefile", "Multisig.mk", "scripts/Standby.mk", "scripts/standby-task.py"):
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        for name in ("task-status.py", "task-status.schema.json", "new-task.py"):
            source = ROOT / "scripts" / name
            if source.exists():
                shutil.copy2(source, self.repo / "scripts" / name)
        (self.repo / "config").mkdir()
        for network in ("local", "other"):
            (self.repo / "config" / f"{network}.env").write_text("L1_RPC_URL=http://127.0.0.1:1\n")
        self.standby = self.repo / "standby/evm/tasks/delay-upgrade-activation"
        copy_canonical_task(ROOT / "standby/evm/tasks/delay-upgrade-activation", self.standby)
        for args in (("init", "-qb", "main"), ("add", "."),
                     ("-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")):
            result = run("git", *args, cwd=self.repo)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.task = self.repo / "active/evm/tasks" / TASK

    def cli(self, *args):
        return run("python3", "-B", str(self.repo / "scripts/task-status.py"), *args, cwd=self.repo)

    def check(self):
        return self.cli("check", "--repo", str(self.repo))

    def write_status(self, data=None, task=None):
        task = task or self.task
        task.mkdir(parents=True, exist_ok=True)
        (task / "status.json").write_text(json.dumps(data if data is not None else status()) + "\n")

    def config(self, task=None, network="local", readme="READY TO SIGN"):
        config = (task or self.task) / "config" / network
        config.mkdir(parents=True, exist_ok=True)
        (config / "README.md").write_text(f"# Example\n\nStatus: {readme}\n")

    def assert_ok(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def assert_problem(self, result, path, message):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(path), result.stdout + result.stderr)
        self.assertIn(message, result.stdout + result.stderr)


class TaskStatus(TaskFixture):
    def test_missing_active_status_lists_every_path(self):
        self.config()
        second = self.task.with_name("2026-10-21-second")
        second.mkdir()
        result = self.check()
        self.assert_problem(result, self.task / "status.json", "missing")
        self.assertIn(str(second / "status.json"), result.stderr)

    def test_schema_and_identity_errors(self):
        self.config()
        cases = []
        for key, value in (("schema_version", True), ("kind", "standby"), ("task", "wrong"),
                           ("last_updated", "yesterday"), ("extra", 1)):
            data = status()
            data[key] = value
            cases.append((key, data))
        for key, value in (("step", "unknown"), ("executed_tx", "0x1234"), ("extra", 1),
                           ("pr", "https://example.invalid/not-a-pull"), ("blocksec_ticket", "http://example.invalid"),
                           ("signatures", {"base-signer": {"collected": -1, "required": 0}}),
                           ("signatures", {"base-signer": {"collected": True, "required": 1}}),
                           ("signatures", {"base-signer": {"collected": 0, "required": 1, "extra": 1}})):
            data = status()
            data["networks"]["local"][key] = value
            cases.append((key, data))
        data = status()
        del data["networks"]["local"]["pr"]
        cases.append(("pr", data))
        for field, data in cases:
            with self.subTest(field=field, data=data):
                self.write_status(data)
                self.assert_problem(self.check(), self.task / "status.json", field)

    def test_network_keys_must_match_config_directories(self):
        self.config()
        for networks in ({}, {"other": status()["networks"]["local"]},
                         {"local": status()["networks"]["local"], "Bad": status()["networks"]["local"]}):
            with self.subTest(networks=networks):
                data = status()
                data["networks"] = networks
                self.write_status(data)
                self.assert_problem(self.check(), self.task / "status.json", "networks")

    def test_execution_requires_transaction_and_only_execution_allows_it(self):
        self.config()
        for step, tx in (("executed", None), ("authoring", TX), ("canceled", TX)):
            with self.subTest(step=step):
                data = status()
                data["networks"]["local"].update(step=step, executed_tx=tx)
                self.write_status(data)
                self.assert_problem(self.check(), self.task / "status.json", "executed_tx")

    def test_executed_transaction_rejects_trailing_newline(self):
        self.config(readme="EXECUTED")
        data = status()
        data["networks"]["local"].update(step="executed", executed_tx=TX + "\n")
        self.write_status(data)
        self.assert_problem(self.check(), self.task / "status.json", "executed_tx")

    def test_final_readme_and_step_must_agree_in_both_directions(self):
        for final in ("EXECUTED", "CANCELED"):
            for form in (final, f"{final} https://example.invalid/result", f"[{final}](https://example.invalid/result)"):
                with self.subTest(final=final, form=form):
                    self.config(readme=form)
                    self.write_status()
                    self.assert_problem(self.check(), self.task / "config/local/README.md", "step")
                    data = status()
                    data["networks"]["local"].update(step=final.lower(), executed_tx=TX if final == "EXECUTED" else None)
                    self.write_status(data)
                    self.assert_ok(self.check())
                    self.config(readme="READY TO SIGN")
                    self.assert_problem(self.check(), self.task / "config/local/README.md", "step")
        self.config(readme="EXECUTED\nStatus: CANCELED")
        self.assert_problem(self.check(), self.task / "config/local/README.md", "step")

    def test_final_looking_readme_requires_supported_format(self):
        self.write_status()
        for value in ("EXECUTED (https://example.invalid/tx/123)",
                      "CANCELED because the rollout was superseded",
                      "executed", "canceled",
                      "[EXECUTED](https://example.invalid/result) extra",
                      "[canceled](https://example.invalid/result)"):
            with self.subTest(value=value):
                self.config(readme=value)
                self.assert_problem(self.check(), self.task / "config/local/README.md",
                                    "expected EXECUTED or CANCELED")

    def test_standby_status_exists_only_during_invocation(self):
        self.assert_ok(self.check())
        self.write_status(status(self.standby.name, "standby"), self.standby)
        self.assert_problem(self.check(), self.standby / "status.json", "no invocation")
        (self.standby / "status.json").unlink()
        self.config(self.standby)
        self.assert_problem(self.check(), self.standby / "status.json", "missing")
        self.write_status(status(self.standby.name, "standby"), self.standby)
        self.assert_ok(self.check())

    def test_status_is_rejected_anywhere_in_signed_config(self):
        for task, kind in ((self.task, "active"), (self.standby, "standby")):
            self.config(task)
            self.write_status(status(task.name, kind), task)
            for name in ("status.json", "local/status.json", "local/validations/status.json"):
                with self.subTest(kind=kind, path=name):
                    misplaced = task / "config" / name
                    misplaced.parent.mkdir(parents=True, exist_ok=True)
                    misplaced.write_text("{}\n")
                    self.assert_problem(self.check(), misplaced, "outside config/")
                    misplaced.unlink()
        self.assert_ok(self.check())

    def test_add_network_preserves_existing_progress_and_refuses_duplicates(self):
        self.config()
        self.assert_ok(self.cli("add-network", str(self.task), "local"))
        self.assert_ok(self.check())
        self.assertTrue((self.task / "status.json").is_file(), "add-network did not create status.json")
        data = json.loads((self.task / "status.json").read_text())
        data["networks"]["local"]["step"] = "review"
        self.write_status(data)
        self.config(network="other")
        self.assert_ok(self.cli("add-network", str(self.task), "other"))
        self.assert_ok(self.check())
        saved = (self.task / "status.json").read_bytes()
        self.assertEqual(json.loads(saved)["networks"]["local"], data["networks"]["local"])
        self.assert_problem(self.cli("add-network", str(self.task), "other"), self.task / "status.json", "already exists")
        self.assertEqual((self.task / "status.json").read_bytes(), saved)

    def test_schema_file_drives_validation(self):
        self.config()
        self.write_status()
        schema_path = self.repo / "scripts/task-status.schema.json"
        schema = json.loads(schema_path.read_text())
        schema["properties"]["schema_version"]["const"] = 2
        schema_path.write_text(json.dumps(schema))
        self.assert_problem(self.check(), self.task / "status.json", "schema_version")


class NewTask(TaskFixture):
    def make(self, *inputs, env=None):
        return run("make", "new-task", *inputs, cwd=self.repo, env=env)

    def snapshot(self):
        return {str(p.relative_to(self.repo)): p.read_bytes() for p in self.repo.rglob("*") if p.is_file() and ".git" not in p.parts}

    def test_all_modes_keep_status_outside_signed_config(self):
        self.assert_ok(self.make("TASK_SLUG=example", "TASK_DATE=2026-10-20", "TASK_NETWORK=local"))
        self.assert_ok(self.check())
        self.assertEqual({str(p.relative_to(self.task)) for p in self.task.rglob("*") if p.is_file()},
                         {"Makefile", "FACILITATOR.md", "script/.gitkeep", "config/local/.env", "config/local/README.md", "status.json"})
        before = self.snapshot()
        self.assert_ok(self.make(f"TASK_ID={TASK}", "TASK_NETWORK=other"))
        self.assert_ok(self.check())
        for name, data in before.items():
            if name != f"active/evm/tasks/{TASK}/status.json":
                self.assertEqual((self.repo / name).read_bytes(), data, name)
        canonical = {str(p.relative_to(self.standby)): p.read_bytes() for p in self.standby.rglob("*") if p.is_file()}
        self.assert_ok(self.make(f"STANDBY_OP={self.standby.name}", "TASK_NETWORK=local"))
        self.assert_ok(self.check())
        for name, data in canonical.items():
            self.assertEqual((self.standby / name).read_bytes(), data, name)
        for task in (self.task, self.standby):
            self.assertTrue((task / "status.json").is_file())
            self.assertFalse(list((task / "config").rglob("status.json")))
            self.assertNotIn("RECORD_STATE_DIFF", (task / "config/local/.env").read_text())
            self.assertIn("BASE_CONTRACTS_COMMIT=\n", (task / "config/local/.env").read_text())
            self.assertIn("Status: READY TO SIGN", (task / "config/local/README.md").read_text())
        parsed = run("make", "TASK_NETWORK=local", "-n", "forge-deps", cwd=self.task)
        self.assert_ok(parsed)
        missing = run("make", "-n", "forge-deps", cwd=self.task)
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn("command line", missing.stderr)

    def test_refusals_do_not_write_files(self):
        cases = [
            ([], "exactly one"), (["TASK_SLUG=example", "TASK_ID=" + TASK], "exactly one"),
            (["TASK_SLUG=example", "STANDBY_OP=delay-upgrade-activation"], "exactly one"),
            (["TASK_ID=2026-10-20-missing"], "existing active task"),
            (["STANDBY_OP=missing"], "existing standby operation"),
            (["TASK_SLUG=../escape"], "invalid"), (["TASK_SLUG=Bad"], "invalid"),
            (["TASK_ID=../escape"], "invalid"), (["STANDBY_OP=../escape"], "invalid"),
            (["TASK_SLUG=example", "TASK_NETWORK=unknown"], "global network"),
            (["TASK_SLUG=example", "TASK_NETWORK=../escape"], "invalid"),
            (["TASK_SLUG=example", "TASK_NETWORK=0local"], "invalid"),
            (["TASK_SLUG=example", "TASK_NETWORK=local--bad"], "invalid"),
        ]
        cases += [(["TASK_SLUG=example", f"TASK_DATE={date}"], "invalid TASK_DATE") for date in ("2026-02-30", "20261020", "../escape")]
        for inputs, message in cases:
            with self.subTest(inputs=inputs):
                before = self.snapshot()
                result = self.make("TASK_NETWORK=local", *inputs)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stdout + result.stderr)
                self.assertEqual(self.snapshot(), before)
        for env in (None, dict(os.environ, TASK_NETWORK="local")):
            result = self.make("TASK_SLUG=example", env=env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("command line", result.stderr)

    def test_overwrites_leave_existing_files_unchanged(self):
        self.assert_ok(self.make("TASK_SLUG=example", "TASK_DATE=2026-10-20", "TASK_NETWORK=local"))
        self.assert_ok(self.make(f"STANDBY_OP={self.standby.name}", "TASK_NETWORK=local"))
        before = self.snapshot()
        for selector in ("TASK_SLUG=example", f"TASK_ID={TASK}", f"STANDBY_OP={self.standby.name}"):
            with self.subTest(selector=selector):
                result = self.make(selector, "TASK_DATE=2026-10-20", "TASK_NETWORK=local")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("already exists", result.stdout + result.stderr)
                self.assertEqual(self.snapshot(), before)

    def test_existing_active_identifier_does_not_require_a_date_prefix(self):
        task = self.task.with_name("example")
        self.config(task)
        self.write_status(status("example"), task)
        self.assert_ok(self.make("TASK_ID=example", "TASK_NETWORK=other"))
        self.assert_ok(self.check())

    def test_existing_networks_must_be_adopted_before_adding_another(self):
        self.config()
        before = self.snapshot()
        result = self.make(f"TASK_ID={TASK}", "TASK_NETWORK=other")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("status.json", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_existing_invalid_status_does_not_leave_partial_network(self):
        self.config()
        self.write_status({"unexpected": True})
        before = self.snapshot()
        result = self.make(f"TASK_ID={TASK}", "TASK_NETWORK=other")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("status.json", result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)


if __name__ == "__main__":
    unittest.main()
