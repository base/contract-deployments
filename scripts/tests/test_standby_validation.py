from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shlex
import threading

from scripts.tests.test_standby_lifecycle import ROOT, StandbyFixture, copy_canonical_task, run


class FixtureRPC(BaseHTTPRequestHandler):
    def do_POST(self):
        request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        response = {"jsonrpc": "2.0", "id": request["id"]}
        if request["method"] == "eth_chainId":
            response["result"] = "0x7a69"
        else:
            response["error"] = {"code": -32601, "message": "fixture supports chain ID only"}
        encoded = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, *args):
        pass


class StandbyValidation(StandbyFixture):
    def setUp(self):
        super().setUp()
        signer = Path(os.environ["STANDBY_SIGNER_HOME"])
        rpc = ThreadingHTTPServer(("127.0.0.1", 0), FixtureRPC)
        self.addCleanup(rpc.server_close)
        self.addCleanup(rpc.shutdown)
        threading.Thread(target=rpc.serve_forever, daemon=True).start()
        network_env = self.repo / "config/local.env"
        network_env.write_text(network_env.read_text().replace("127.0.0.1:1", f"127.0.0.1:{rpc.server_port}"))
        bin_dir = self.repo / "bin"
        bin_dir.mkdir()
        for tool in ("mise", "ottr-cli"):
            stub = bin_dir / tool
            stub.write_text(f'#!/bin/sh\nexec python3 "$SOURCE_ROOT/scripts/tests/credential-stubs.py" {tool} "$@"\n')
            stub.chmod(0o755)
        node = run("mise", "-C", str(ROOT), "which", "node", cwd=ROOT)
        self.assertEqual(node.returncode, 0, node.stderr)
        self.env.update(
            PATH=f"{bin_dir}:{os.environ['PATH']}", ORIGINAL_PATH=os.environ["PATH"],
            ORIGINAL_HOME=os.environ["HOME"], HOME=str(self.repo / "home"), SOURCE_ROOT=str(ROOT),
            PINNED_NODE=node.stdout.strip(), STANDBY_SIGNER_HOME=str(signer),
            SIGNER_SMOKE_MARKER=str(self.repo / "opened"),
        )
        (self.repo / "signer-tool").mkdir()
        overrides = self.repo / "offline.mk"
        overrides.write_text(".PHONY: bootstrap-mise checkout-signer-tool deps-signer-tool\nbootstrap-mise checkout-signer-tool deps-signer-tool: ; @true\n")
        self.options = ("-f", "Makefile", "-f", str(overrides))

    def test_pinned_generator_and_signer_entry(self):
        options = self.options
        before = self.snapshot()
        result = self.make("prepare", "local", *options)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.snapshot(), before)
        result = self.make("gen-validation-cb", "local", *options)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        validation = json.loads((self.config / "validations/base-signer.json").read_text())
        call = json.loads((self.config / "validations/.call-fixture.json").read_text())
        expected = run("mise", "-C", str(ROOT), "exec", "--", "cast", "calldata", "delayTimestamp(uint256,uint64)", "0", "20000", cwd=ROOT)
        self.assertEqual(expected.returncode, 0, expected.stderr)
        self.assertEqual(call["calldata"], expected.stdout.strip())
        self.assertEqual(call["target"].lower(), "0x0000000000000000000000000000000000001234")
        self.assertEqual((call["count"], call["operation"], call["value"]), (1, 0, 0))
        responder = "0x000000000000000000000000000000000000beef"
        self.assertEqual(call["safe"].lower(), responder)
        self.assertEqual(validation["expectedDomainAndMessageHashes"]["address"].lower(), responder)
        self.assertEqual([entry["address"].lower() for entry in validation["stateOverrides"]], [responder])
        self.assertTrue(any(entry["address"].lower() == call["target"] for entry in validation["stateChanges"]))
        self.assertTrue(validation["skipTaskOriginValidation"])
        tokens = shlex.split(validation["cmd"])
        self.assertEqual(tokens[tokens.index("--sig") + 1:tokens.index("--sig") + 3], ["sign(address[])", "[]"])
        self.assertIn("UPGRADE_ID=0", tokens)
        self.assertNotIn("SECURITY_COUNCIL", validation["cmd"])
        self.assertNotIn("RECORD_STATE_DIFF", (self.config / ".env").read_text())
        result = self.make("sign-task", "local", *options)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.repo / "opened").read_text(), "opened")

    def test_verifier_deployment_and_both_nested_validations(self):
        self.task = self.repo / "standby/evm/tasks/update-verifier-hashes"
        copy_canonical_task(ROOT / "standby/evm/tasks/update-verifier-hashes", self.task)
        self.config = self.task / "config/local"
        self.config.mkdir(parents=True)
        (self.config / ".env").write_text(
            "BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962\nGAME_TYPE=42\n"
            "CURRENT_AGGREGATE_VERIFIER=0x0000000000000000000000000000000000001111\n"
            + "".join(f"AGGREGATE_VERIFIER_{key}_HASH=0x{value:064x}\n" for key, value in (("TEE_IMAGE", 4), ("ZK_RANGE", 5), ("ZK_AGGREGATE", 6)))
        )
        (self.config / "README.md").write_text("Status: READY TO SIGN\n\n# Fixture verifier rotation\n")
        (self.config / "addresses.json").write_text('{"aggregateVerifier":"0x0000000000000000000000000000000000002222"}\n')
        network_env = self.repo / "config/local.env"
        network_env.write_text(network_env.read_text() + "DISPUTE_GAME_FACTORY_PROXY=0x0000000000000000000000000000000000001234\nPROXY_ADMIN_OWNER=0x000000000000000000000000000000000000beef\nCB_MULTISIG=0x000000000000000000000000000000000000cafe\nBASE_SECURITY_COUNCIL=0x000000000000000000000000000000000000face\n")
        canonical = {name: data for name, data in self.snapshot().items() if not name.startswith("config/")}
        result = self.make("prepare", "local", *self.options)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        domains = set()
        for target, filename, inner in (("gen-validation-cb", "base-signer.json", "cafe"), ("gen-validation-sc", "security-council-signer.json", "face")):
            with self.subTest(target=target):
                replacement = json.loads((self.config / "addresses.json").read_text())["aggregateVerifier"]
                result = self.make(target, "local", *self.options)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                validation = json.loads((self.config / "validations" / filename).read_text())
                call = json.loads((self.config / "validations/.call-fixture.json").read_text())
                expected = run("mise", "-C", str(ROOT), "exec", "--", "cast", "calldata", "setImplementation(uint32,address)", "42", replacement, cwd=ROOT)
                self.assertEqual(expected.returncode, 0, expected.stderr)
                self.assertEqual(call["calldata"], expected.stdout.strip())
                safe = "0x" + inner.rjust(40, "0")
                self.assertEqual(call["target"].lower(), "0x0000000000000000000000000000000000001234")
                self.assertEqual((call["count"], call["operation"], call["value"]), (1, 0, 0))
                self.assertEqual(call["safe"].lower(), safe)
                self.assertEqual(validation["expectedDomainAndMessageHashes"]["address"].lower(), "0x000000000000000000000000000000000000beef")
                domains.add(validation["expectedDomainAndMessageHashes"]["domainHash"])
                self.assertEqual({entry["address"].lower() for entry in validation["stateOverrides"]}, {safe, "0x000000000000000000000000000000000000beef"})
                self.assertTrue(any(entry["address"].lower() == call["target"].lower() for entry in validation["stateChanges"]))
                self.assertTrue(validation["skipTaskOriginValidation"])
                self.assertIn(safe, validation["cmd"].lower())
                self.assertIn("BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962", validation["cmd"])
                tokens = shlex.split(validation["cmd"])
                self.assertFalse(any(Path(token.split("=", 1)[-1]).is_absolute() for token in tokens))
                self.assertNotIn("PRESTATE_JSON", validation["cmd"])
                self.assertNotIn("FOUNDRY_CONFIG", validation["cmd"])
        self.assertEqual(len(domains), 2)
        deployed = json.loads((self.config / "addresses.json").read_text())
        self.assertNotEqual(int(deployed["aggregateVerifier"], 16), 0)
        self.assertGreater(len(deployed["aggregateVerifierConstructorArgs"]), 2)
        self.assertEqual({name: data for name, data in self.snapshot().items() if not name.startswith("config/")}, canonical)
        self.assertFalse((self.repo / "active/evm/records").exists())
