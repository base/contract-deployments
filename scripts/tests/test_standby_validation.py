from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shlex
import threading

from scripts.tests.test_standby_lifecycle import ROOT, StandbyFixture, run


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
    def test_pinned_generator_and_signer_entry(self):
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
        options = ("-f", "Makefile", "-f", str(overrides))
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
