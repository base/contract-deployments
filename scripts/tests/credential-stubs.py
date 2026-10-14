#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import sys


def main():
    tool, *args = sys.argv[1:]
    if tool == "ottr-cli":
        directory = Path.home() / ".ottr"
        directory.mkdir(parents=True, exist_ok=True)
        subprocess.run([
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
            "-subj", "/CN=fixture", "-addext", "subjectAltName=URI:user:///fixture@example.invalid",
            "-keyout", str(directory / "device-certificate-key.pem"), "-out", str(directory / "device-certificate.pem"),
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return
    if args[:2] != ["exec", "--"]:
        raise ValueError(f"unexpected mise command: {args}")
    args = args[2:]
    if args[:2] == ["cast", "call"]:
        if "incidentResponder()(address)" in args:
            print("0x000000000000000000000000000000000000beef")
        elif "getOwners()(address[])" in args:
            print("[0x0000000000000000000000000000000000009999]")
        else:
            raise ValueError(f"unexpected RPC bootstrap call: {args}")
    elif args[:2] == ["forge", "script"]:
        if args[args.index("--sig") + 1:args.index("--sig") + 3] != ["sign(address[])", "[]"]:
            raise ValueError("fixture only supports the direct responder signing simulation")
        if os.environ.get("RECORD_STATE_DIFF") != "true":
            raise ValueError("the real signer generator must inject RECORD_STATE_DIFF=true")
        env = dict(os.environ, PATH=os.environ["ORIGINAL_PATH"], HOME=os.environ["ORIGINAL_HOME"])
        for key in ("PROTOCOL_VERSIONS_PROXY", "UPGRADE_ID", "EXPECTED_CURRENT_TIMESTAMP", "NEW_TIMESTAMP"):
            env["FIXTURE_" + key] = os.environ[key]
        env["FIXTURE_SENDER"] = args[args.index("--sender") + 1]
        env["STANDBY_STATE_DIFF_OUT"] = str(Path.cwd() / "stateDiff.json")
        script = next(token for token in args if token.endswith(":DelayUpgradeActivation"))
        env["STANDBY_SCRIPT_SOURCE"] = str(Path(script.rsplit(":", 1)[0]).resolve())
        subprocess.run(["sh", os.environ["SOURCE_ROOT"] + "/scripts/tests/run-standby-solidity.sh"], env=env, check=True)
    elif args[:2] == ["npx", "tsx"]:
        out = Path(args[args.index("--out") + 1])
        out.parent.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ, STANDBY_VALIDATION_OUT=str(out.parent / ".call-fixture.json"))
        signer = Path(os.environ["STANDBY_SIGNER_HOME"])
        subprocess.run([os.environ["PINNED_NODE"], str(signer / "node_modules/tsx/dist/cli.mjs"), *args[2:]], cwd=signer, env=env, check=True)
    elif args[:3] == ["npm", "run", "dev"]:
        marker = Path(os.environ["SIGNER_SMOKE_MARKER"])
        if Path.cwd() != (marker.parent / "signer-tool").resolve():
            raise ValueError("signer entry must run from the isolated signer checkout")
        marker.write_text("opened")
    elif args != ["npm", "ci"]:
        raise ValueError(f"unexpected fixture command: {args}")


if __name__ == "__main__":
    main()
