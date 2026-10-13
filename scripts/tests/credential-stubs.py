#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile


def simulate(command, out, state_diff=None):
    tokens = shlex.split(command)
    env = dict(os.environ, PATH=os.environ["ORIGINAL_PATH"], HOME=os.environ["ORIGINAL_HOME"], STANDBY_VALIDATION_OUT=str(out))
    for key in ("PROTOCOL_VERSIONS_PROXY", "UPGRADE_ID", "EXPECTED_CURRENT_TIMESTAMP", "NEW_TIMESTAMP"):
        if key in os.environ:
            env["FIXTURE_" + key] = os.environ[key]
    for token in tokens:
        if "=" not in token:
            break
        key, value = token.split("=", 1)
        env["FIXTURE_" + key] = value
    if "--sender" in tokens:
        env["FIXTURE_SENDER"] = tokens[tokens.index("--sender") + 1]
    script = next(token for token in tokens if token.endswith(":DelayUpgradeActivation"))
    source = Path(script.rsplit(":", 1)[0]).resolve()
    if not source.is_file():
        raise ValueError(f"validation script path does not resolve from workdir: {source}")
    env["STANDBY_SCRIPT_SOURCE"] = str(source)
    if state_diff is not None:
        env["STANDBY_STATE_DIFF_OUT"] = str(state_diff)
    subprocess.run(["sh", os.environ["SOURCE_ROOT"] + "/scripts/tests/run-standby-solidity.sh"], env=env, check=True)


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
        return
    args = args[2:]
    if args[:2] == ["cast", "call"]:
        print("0x000000000000000000000000000000000000beef" if "incidentResponder()(address)" in args else "[0x0000000000000000000000000000000000009999]")
    elif args[:2] == ["forge", "script"]:
        if "sign(address[])" not in args or "[]" not in args:
            raise ValueError("fixture only supports the direct responder signing simulation")
        simulate(" ".join(shlex.quote(token) for token in sys.argv[2:]), Path(os.environ["CALL_FIXTURE_OUT"]), Path.cwd() / "stateDiff.json")
    elif args[:2] == ["npx", "tsx"]:
        out = Path(args[args.index("--out") + 1])
        out.parent.mkdir(parents=True, exist_ok=True)
        command = args[args.index("--forge-cmd") + 1]
        signer = os.environ.get("STANDBY_SIGNER_HOME")
        if signer:
            env = dict(os.environ, HOME=str(Path(os.environ["FIXTURE_HOME"])), CALL_FIXTURE_OUT=str(out.parent / ".call-fixture.json"))
            node = shutil.which("node", path=os.environ["ORIGINAL_PATH"])
            workdir = Path(args[args.index("--workdir") + 1])
            source = next(token for token in shlex.split(command) if token.endswith(":DelayUpgradeActivation"))
            source = (workdir / source.rsplit(":", 1)[0]).resolve()
            with tempfile.TemporaryDirectory(prefix=".forge-fixture-", dir=out.parent) as project:
                env["STANDBY_PROJECT_DIR"] = project
                prepare = dict(env, PATH=os.environ["ORIGINAL_PATH"], HOME=os.environ["ORIGINAL_HOME"], STANDBY_SCRIPT_SOURCE=str(source), STANDBY_PREPARE_ONLY="1")
                subprocess.run(["sh", os.environ["SOURCE_ROOT"] + "/scripts/tests/run-standby-solidity.sh"], env=prepare, check=True)
                subprocess.run([node, str(Path(signer) / "node_modules/tsx/dist/cli.mjs"), *args[2:]], cwd=signer, env=env, check=True)
        else:
            content = {"cmd": command}
            if os.environ.get("STANDBY_SOLIDITY_INTEGRATION") == "1":
                workdir = args[args.index("--workdir") + 1]
                previous = Path.cwd()
                os.chdir(workdir)
                try:
                    simulate(command, out)
                finally:
                    os.chdir(previous)
                content.update(json.loads(out.read_text()))
            out.write_text(json.dumps(content))
    elif args[:3] == ["npm", "run", "dev"]:
        Path(os.environ["SIGNER_SMOKE_MARKER"]).write_text("opened")


if __name__ == "__main__":
    main()
