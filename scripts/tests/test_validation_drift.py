import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/validation-drift.py"


def run(*args, cwd=None, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)


def validation():
    return {
        "cmd": "mise exec -- forge script --rpc-url http://localhost tasks/example/script/X.s.sol:X",
        "rpcUrl": "http://localhost", "ledgerId": 1,
        "expectedDomainAndMessageHashes": {"address": "0x1", "messageHash": "0xaa"},
        "stateOverrides": [{"address": "0x1", "name": "Safe", "overrides": [
            {"key": "0x4", "value": "0x1", "description": "Threshold", "allowDifference": False}]}],
        "stateChanges": [{"address": "0x1", "name": "Safe", "changes": [
            {"key": "0x5", "before": "0x1", "after": "0x2", "description": "Nonce", "allowDifference": False}]}],
        "balanceChanges": [{"address": "0x2", "before": "0", "after": "1", "name": "Recipient"}],
        "taskOriginConfig": {"identity": "author"},
    }


class DriftFixture(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.repo = Path(temp.name)
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True, capture_output=True)
        self.task = self.repo / "active/evm/tasks/example"
        self.config = self.task / "config/local"
        self.file = self.config / "validations/base-signer.json"
        self.put("active/evm/tasks/example/Makefile", "gen-validation-cb:\n\t$(call GEN_VALIDATION,$(SCRIPT),$(call addr,A,B),$(SENDER),base-signer.json,)\n")
        self.put("active/evm/tasks/example/script/X.s.sol", 'import {Common} from "script/common/Common.sol";\n')
        self.put("active/evm/script/common/Common.sol", 'import "./Nested.sol";\nimport "forge-std/Script.sol";\n')
        self.put("active/evm/script/common/Nested.sol", "pragma solidity 0.8.15;\n")
        self.put("active/evm/foundry.toml", '[profile.default]\nremappings = ["forge-std/=lib/forge-std/src/"]\n')
        self.put("config/local.env", "L1_RPC_URL=http://localhost\n")
        self.put("active/evm/tasks/example/config/local/.env", "BASE_CONTRACTS_COMMIT=abc\n")
        self.put("active/evm/tasks/example/config/local/addresses.json", '{"deployed":"0x1"}\n')
        self.put("active/evm/tasks/example/config/local/README.md", "Status: READY TO SIGN\n")
        self.write_json(self.file, validation())

    def put(self, path, content):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
        return target

    def write_json(self, path, data):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

    def cli(self, *args):
        return run("python3", "-B", str(SCRIPT), *map(str, args))

    def check(self):
        return self.cli("check", "--repo", self.repo)

    def stamp(self, *files):
        result = self.cli("stamp", "--task-dir", self.task, "--network", "local", *(files or [self.file]))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def assert_error(self, result, message):
        self.assertNotEqual(result.returncode, 0, "expected drift failure: " + message)
        self.assertIn(message, result.stdout + result.stderr)


class InputChecks(DriftFixture):
    def test_missing_declared_file(self):
        self.file.unlink()
        self.assert_error(self.check(), "base-signer.json")

    def test_missing_fingerprint(self):
        self.assert_error(self.check(), "taskInputs")

    def test_each_input_change_is_named(self):
        inputs = ["Makefile", "script/X.s.sol", "config/local/.env", "config/local/addresses.json"]
        paths = [self.task / name for name in inputs] + [self.repo / "config/local.env", self.repo / "active/evm/script/common/Nested.sol"]
        for path in paths:
            with self.subTest(path=path.relative_to(self.repo)):
                self.stamp()
                path.write_bytes(path.read_bytes() + b"\n")
                self.assert_error(self.check(), path.relative_to(self.repo).as_posix())

    def test_direct_common_script_and_its_imports(self):
        shutil.rmtree(self.task / "script")
        data = validation()
        data["cmd"] = 'FOO=bar mise exec -- forge script --broadcast --rpc-url http://localhost "script/common/Common.sol:Common" --sig "sign(address[])" "[]"'
        self.write_json(self.file, data)
        for name in ["Common.sol", "Nested.sol"]:
            with self.subTest(name=name):
                self.stamp()
                result = self.check()
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                path = self.repo / "active/evm/script/common" / name
                path.write_text(path.read_text() + "\n")
                self.assert_error(self.check(), "changed: " + path.relative_to(self.repo).as_posix())

    def test_network_json_input_drift(self):
        path = self.config / "funding.json"
        self.write_json(path, {"recipient": "0x1", "amount": "1"})
        self.stamp()
        self.write_json(path, {"recipient": "0x1", "amount": "2"})
        self.assert_error(self.check(), "changed: " + path.relative_to(self.repo).as_posix())

    def test_refreshing_prestate_does_not_change_signed_inputs(self):
        path = self.config / "prestate.json"
        self.write_json(path, {"gameCount": 1})
        self.stamp()
        self.write_json(path, {"gameCount": 2})
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignored_local_files_can_disappear_after_stamping(self):
        self.put(".gitignore", ".DS_Store\n.env.local\n")
        paths = [self.config / ".DS_Store", self.config / ".env.local", self.task / "script/.DS_Store"]
        for path in paths:
            path.write_text("local bytes\n")
        self.stamp()
        for path in paths:
            path.unlink()
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_tracked_file_matching_ignore_rule_is_still_checked(self):
        self.put(".gitignore", "addresses.json\n")
        path = self.config / "addresses.json"
        subprocess.run(["git", "-C", str(self.repo), "add", "-f", str(path)], check=True, capture_output=True)
        self.stamp()
        path.write_text('{"deployed":"0x2"}\n')
        self.assert_error(self.check(), "changed: " + path.relative_to(self.repo).as_posix())

    def test_plain_directory_fingerprints_include_inputs(self):
        self.stamp()
        shutil.rmtree(self.repo / ".git")
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        path = self.config / "addresses.json"
        path.write_text('{"deployed":"0x2"}\n')
        self.assert_error(self.check(), "changed: " + path.relative_to(self.repo).as_posix())

    def test_missing_pending_network_environment(self):
        self.stamp()
        (self.config / ".env").unlink()
        (self.config / "README.md").unlink()
        self.assert_error(self.check(), "example/local: missing .env")
        shutil.rmtree(self.file.parent)
        (self.config / "README.md").write_text("Status: READY TO SIGN\n")
        self.assert_error(self.check(), "example/local: missing .env")

    def test_finalized_network_without_environment_is_skipped(self):
        (self.config / ".env").unlink()
        for status in ["EXECUTED", "CANCELED"]:
            with self.subTest(status=status):
                (self.config / "README.md").write_text(f"Status: {status}\n")
                result = self.check()
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Skipped", result.stdout)

    def test_ambiguous_or_nonfinal_status_does_not_skip_validation(self):
        self.file.unlink()
        for text in [
            "Status: READY TO SIGN\nStatus: EXECUTED\n",
            "Status: EXECUTED\nStatus: READY TO SIGN\n",
            "\n" * 20 + "Status: EXECUTED\n",
            "Status: EXECUTED previously\n",
            "Status: canceled\n",
        ]:
            with self.subTest(readme=text):
                (self.config / "README.md").write_text(text)
                self.assert_error(self.check(), "missing validation base-signer.json")

    def test_stamp_skips_unsupported_layouts_without_changing_output(self):
        before = self.file.read_bytes()
        for path in [self.task / "Makefile", self.config]:
            with self.subTest(path=path):
                moved = path.with_name(path.name + ".unused")
                path.rename(moved)
                try:
                    result = self.cli("stamp", "--task-dir", self.task, "--network", "local", self.file)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn("layout is not supported by the fingerprint check", result.stdout)
                finally:
                    moved.rename(path)
                self.assertEqual(self.file.read_bytes(), before)

    def test_check_skips_task_without_makefile(self):
        (self.task / "Makefile").rename(self.task / "Task.mk")
        (self.config / ".env").rename(self.config / "network.env")
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("example: layout is not supported by the fingerprint check", result.stdout)

    def test_standby_own_forge_project(self):
        task = self.repo / "standby/evm/tasks/example"
        task.parent.mkdir(parents=True)
        self.task.rename(task)
        self.task = task
        self.config = task / "config/local"
        self.file = self.config / "validations/base-signer.json"
        shutil.rmtree(task / "script")
        self.put("standby/evm/tasks/example/foundry.toml", "[profile.default]\n")
        self.put("standby/evm/tasks/example/shared/Common.sol", 'import "./Nested.sol";\n')
        path = self.put("standby/evm/tasks/example/shared/Nested.sol", "pragma solidity 0.8.15;\n")
        data = validation()
        data["cmd"] = "mise exec -- forge script --rpc-url http://localhost shared/Common.sol:Common"
        self.write_json(self.file, data)
        self.stamp()
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        path.write_text(path.read_text() + "\n")
        self.assert_error(self.check(), "changed: " + path.relative_to(self.repo).as_posix())

    def test_added_and_removed_inputs_are_named(self):
        for relative in ["script/New.sol", "config/local/addresses.json"]:
            with self.subTest(relative=relative):
                path = self.task / relative
                path.unlink(missing_ok=True)
                self.stamp()
                path.write_text("new input\n")
                self.assert_error(self.check(), "added: " + path.relative_to(self.repo).as_posix())
                self.stamp()
                path.unlink()
                self.assert_error(self.check(), "removed: " + path.relative_to(self.repo).as_posix())

    def test_undeclared_validation(self):
        self.stamp()
        self.write_json(self.file.with_name("surprise.json"), {})
        self.assert_error(self.check(), "undeclared validation")

    def test_stamp_round_trip_and_format(self):
        original = validation()
        original["note"] = "Review café"
        self.write_json(self.file, original)
        self.stamp()
        stamped = json.loads(self.file.read_text())
        inputs = stamped.pop("taskInputs", None)
        self.assertIsNotNone(inputs, "stamp must add taskInputs")
        self.assertEqual(stamped, original)
        self.assertEqual(inputs["algorithm"], "sha256")
        expected = sorted([
            "active/evm/tasks/example/Makefile", "active/evm/tasks/example/script/X.s.sol",
            "active/evm/script/common/Common.sol", "active/evm/script/common/Nested.sol",
            "active/evm/tasks/example/config/local/.env", "active/evm/tasks/example/config/local/addresses.json", "config/local.env",
        ])
        self.assertEqual(list(inputs["files"]), expected)
        for path, digest in inputs["files"].items():
            self.assertEqual(digest, hashlib.sha256((self.repo / path).read_bytes()).hexdigest())
        self.assertEqual(self.file.read_text(), json.dumps({**original, "taskInputs": inputs}, indent=2, ensure_ascii=False) + "\n")
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_fingerprint_digest_tampering(self):
        self.stamp()
        data = json.loads(self.file.read_text())
        data["taskInputs"] = {"algorithm": "sha256", "digest": "0" * 64, "files": {}}
        self.write_json(self.file, data)
        self.assert_error(self.check(), "taskInputs")

    def test_finalized_networks_and_empty_standby(self):
        (self.repo / "standby/evm/tasks/canonical").mkdir(parents=True)
        self.put("standby/evm/tasks/canonical/Makefile", "gen-validation-cb:\n\t$(call GEN_VALIDATION,X,,,base-signer.json,)\n")
        self.file.unlink()
        for status in ["EXECUTED", "CANCELED", "[EXECUTED](https://example.invalid/tx)"]:
            with self.subTest(status=status):
                (self.config / "README.md").write_text(f"# Task\n\nStatus: {status}\n")
                result = self.check()
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Skipped", result.stdout)
                self.assertIn("local", result.stdout)

    def test_remapped_imports_and_dependency_exclusion(self):
        self.put("active/evm/remappings.txt", "common/=script/common/\n")
        (self.task / "script/X.s.sol").write_text('import "common/Common.sol";\n')
        self.put("active/evm/lib/forge-std/src/Script.sol", "dependency bytes\n")
        self.stamp()
        files = json.loads(self.file.read_text()).get("taskInputs", {}).get("files", {})
        self.assertIn("active/evm/script/common/Nested.sol", files)
        self.assertNotIn("active/evm/lib/forge-std/src/Script.sol", files)

    def test_automapped_library_imports_are_dependencies(self):
        (self.task / "script/X.s.sol").write_text(
            'import "solady/src/utils/LibString.sol";\n'
            'import "@solady/src/utils/LibString.sol";\n'
            'import "lib-keccak/LibKeccak.sol";\n'
        )
        self.assertFalse((self.repo / "active/evm/lib").exists())
        self.stamp()
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_unresolved_local_import_fails(self):
        self.put("active/evm/remappings.txt", "common/=script/common/\n")
        for name in ["./Missing.sol", "../Missing.sol", "common/Missing.sol"]:
            with self.subTest(name=name):
                (self.task / "script/X.s.sol").write_text(f'import "{name}";\n')
                self.assert_error(self.cli("stamp", "--task-dir", self.task, "--network", "local", self.file), "unresolved import " + name)


class SemanticComparison(DriftFixture):
    def compare(self, committed, regenerated, network="mainnet"):
        other = self.repo / "regenerated.json"
        self.write_json(self.file, committed)
        self.write_json(other, regenerated)
        return self.cli("compare", "--network", network, self.file, other)

    def test_meaningful_differences(self):
        original = validation()
        original["taskInputs"] = {"algorithm": "sha256", "digest": "abc", "files": {}}
        changes = [
            ("cmd", lambda x: x.update(cmd="different")),
            ("rpcUrl", lambda x: x.update(rpcUrl="different")),
            ("ledgerId", lambda x: x.update(ledgerId=2)),
            ("messageHash", lambda x: x["expectedDomainAndMessageHashes"].update(messageHash="0xbb")),
            ("after", lambda x: x["stateChanges"][0]["changes"][0].update(after="0x3")),
            ("key", lambda x: x["stateChanges"][0]["changes"][0].update(key="0x6")),
            ("address", lambda x: x["stateChanges"][0].update(address="0x3")),
            ("stateChanges", lambda x: x["stateChanges"].clear()),
            ("changes", lambda x: x["stateChanges"][0]["changes"].append({"key": "0x6", "after": "0x3"})),
            ("taskInputs", lambda x: x["taskInputs"].update(digest="def")),
        ]
        for path, change in changes:
            with self.subTest(path=path):
                other = copy.deepcopy(original)
                change(other)
                self.assert_error(self.compare(original, other), path)

    def test_facilitator_annotations_and_approved_differences(self):
        committed = validation()
        regenerated = copy.deepcopy(committed)
        regenerated["taskOriginConfig"] = {"identity": "another machine"}
        for field, entries in [("stateChanges", "changes"), ("stateOverrides", "overrides"), ("balanceChanges", None)]:
            left = committed[field][0]
            right = regenerated[field][0]
            left.update(name="Reviewed", description="Reviewed")
            left = left[entries][0] if entries else left
            right = right[entries][0] if entries else right
            left.update(allowDifference=True, description="Reviewed")
            right.update(allowDifference=False)
            for value in ("before", "after", "value"):
                if value in right:
                    right[value] = "different"
        result = self.compare(committed, regenerated)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("No meaningful differences", result.stdout)
        regenerated["name"] = "top-level name is not an annotation"
        self.assert_error(self.compare(committed, regenerated), "$.name")

    def test_non_mainnet_origin_opt_out_is_ignored(self):
        committed = validation()
        del committed["taskOriginConfig"]
        for field in ("skipTaskOriginValidation", "hideTaskOriginSkippedPage"):
            committed[field] = True
        for network in ("local", "sepolia"):
            with self.subTest(network=network):
                result = self.compare(committed, validation(), network=network)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                result = self.compare(validation(), committed, network=network)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_mainnet_origin_opt_out_is_compared_strictly(self):
        for field in ("skipTaskOriginValidation", "hideTaskOriginSkippedPage"):
            committed = validation()
            committed[field] = True
            for value in (None, False):
                with self.subTest(field=field, regenerated=value):
                    regenerated = validation()
                    if value is not None:
                        regenerated[field] = value
                    self.assert_error(self.compare(committed, regenerated), "$." + field)

    def test_entry_order_is_not_a_difference(self):
        committed = validation()
        committed["stateChanges"].append({"address": "0x2", "changes": [{"key": "0x8", "after": "0x9"}]})
        committed["stateChanges"][0]["changes"].append({"key": "0x6", "after": "0x4"})
        regenerated = copy.deepcopy(committed)
        regenerated["stateChanges"].reverse()
        regenerated["stateChanges"][1]["changes"].reverse()
        result = self.compare(committed, regenerated)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


class MakeIntegration(DriftFixture):
    def prepare_make(self, operation=None):
        for name in ["Multisig.mk", "scripts/validation-drift.py", "Makefile", "scripts/Standby.mk", "scripts/standby-task.py", "active/evm/foundry.toml"]:
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        fake = self.put("fake-signer.py", 'import json, pathlib, sys\na = sys.argv\nout = pathlib.Path(a[a.index("--out") + 1])\nout.parent.mkdir(parents=True, exist_ok=True)\nout.write_text(json.dumps({"cmd": a[a.index("--forge-cmd") + 1]}, indent=2) + "\\n")\n')
        (self.repo / "signer-tool").mkdir()
        if operation:
            self.task = self.repo / "standby/evm/tasks" / operation
            shutil.copytree(ROOT / "standby/evm/tasks" / operation, self.task)
            shutil.copytree(self.config, self.task / "config/local")
            self.config = self.task / "config/local"
            self.file = self.config / "validations/base-signer.json"
            if operation == "delay-upgrade-activation":
                (self.config / ".env").write_text("BASE_CONTRACTS_COMMIT=385f21a41f277d287db92fffe88dca41299162ea\nUPGRADE_ID=0\nEXPECTED_CURRENT_TIMESTAMP=100\nNEW_TIMESTAMP=200\n")
            else:
                (self.config / ".env").write_text("BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962\nGAME_TYPE=42\nCURRENT_AGGREGATE_VERIFIER=0x0000000000000000000000000000000000001234\n" + "".join(f"AGGREGATE_VERIFIER_{name}_HASH=0x{value:064x}\n" for name, value in [("TEE_IMAGE", 1), ("ZK_RANGE", 2), ("ZK_AGGREGATE", 3)]))
            (self.repo / "config/local.env").write_text("L1_RPC_URL=http://localhost\nLEDGER_ACCOUNT=0\nPROTOCOL_VERSIONS_PROXY=0x0000000000000000000000000000000000001234\n")
            run("git", "init", "-q", cwd=self.repo)
            text = (self.task / "Makefile").read_text()
        else:
            text = f"REPO_ROOT := {self.repo}\ninclude $(REPO_ROOT)/Multisig.mk\nPROJECT_DIR := $(REPO_ROOT)/active/evm\nSIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool\nRPC_URL := http://localhost\nLEDGER_ACCOUNT := 0\nVALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations\ngen-validation-cb: deps-signer-tool\n\t$(call GEN_VALIDATION,tasks/example/script/X.s.sol:Example,,0x1,base-signer.json,FOO=bar)\n"
        (self.task / "Makefile").write_text(text + f"\nMISE_EXEC := python3 {fake}\ndeps-signer-tool bootstrap-mise checkout-signer-tool:\n\t@true\n")
        self.make_args = ["CB_SENDER=0x1", "SC_SENDER=0x2"]
        self.temp_root = self.repo / "tmp"
        self.temp_root.mkdir()

    def make(self, *args, env=None):
        return run("make", "--no-print-directory", *args, *self.make_args, cwd=self.task,
                   env=dict(env or os.environ, TMPDIR=str(self.temp_root)))

    def test_macro_stamps_without_changing_cmd(self):
        self.prepare_make()
        result = self.make("TASK_NETWORK=local", "gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        generated = json.loads(self.file.read_text())
        self.assertIn("taskInputs", generated, "GEN_VALIDATION must stamp its output")
        self.assertEqual(generated["cmd"], 'FOO=bar mise exec -- forge script --rpc-url http://localhost tasks/example/script/X.s.sol:Example --sig "sign(address[])" "[]" --sender 0x1')

    def test_active_and_standby_regeneration_is_isolated(self):
        for operation in [None, "delay-upgrade-activation", "update-verifier-hashes"]:
            with self.subTest(operation=operation):
                if operation:
                    self.setUp()
                self.prepare_make(operation)
                result = self.make("TASK_NETWORK=local", "gen-validation-cb")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                if operation == "update-verifier-hashes":
                    result = self.make("TASK_NETWORK=local", "gen-validation-sc")
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                before = self.file.read_bytes()
                result = self.make("-j2", "TASK_NETWORK=local", "check-validations")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(self.file.read_bytes(), before)
                result = self.make("-n", "TASK_NETWORK=local", "check-validations")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("VALIDATIONS_DIR", result.stdout)
                data = json.loads(before)
                data["cmd"] = "drift"
                self.write_json(self.file, data)
                self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), "$.cmd")
                self.file.unlink()
                self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), "missing")
                self.write_json(self.file, json.loads(before))
                self.write_json(self.file.with_name("extra.json"), {})
                self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), "extra.json")
                self.assertEqual(list(self.temp_root.iterdir()), [])

    def test_non_mainnet_origin_opt_out_survives_regeneration(self):
        self.prepare_make()
        result = self.make("TASK_NETWORK=local", "gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        data = json.loads(self.file.read_text())
        data.update(skipTaskOriginValidation=True, hideTaskOriginSkippedPage=True)
        self.write_json(self.file, data)
        result = self.make("TASK_NETWORK=local", "check-validations")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_hidden_extra_validation(self):
        self.prepare_make()
        result = self.make("TASK_NETWORK=local", "gen-validation-cb")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.write_json(self.file.with_name(".extra.json"), {})
        self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), ".extra.json")

    def test_missing_committed_validations_directory(self):
        self.prepare_make()
        shutil.rmtree(self.file.parent)
        self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), "missing committed validations directory")
        self.assertEqual(list(self.temp_root.iterdir()), [])

    def test_no_generation_targets(self):
        self.prepare_make()
        path = self.task / "Makefile"
        path.write_text(path.read_text().replace("gen-validation-cb:", "generate-cb:"))
        self.assert_error(self.make("TASK_NETWORK=local", "check-validations"), "no gen-validation targets found")
        self.assertEqual(list(self.temp_root.iterdir()), [])

    def test_network_must_be_on_make_command_line(self):
        self.prepare_make()
        env = dict(os.environ, TASK_NETWORK="local")
        self.assert_error(self.make("check-validations", env=env), "TASK_NETWORK")


if __name__ == "__main__":
    unittest.main()
