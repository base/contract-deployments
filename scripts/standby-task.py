#!/usr/bin/env python3
import argparse
import datetime
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

IDENTIFIER = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*\Z")
INVOCATION_DIRS = {"config", "records", "signatures"}
INVOCATION_FILES = {"status.json"}

spec = importlib.util.spec_from_file_location("task_status", Path(__file__).with_name("task-status.py"))
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


def identifier(value, label):
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"invalid {label}: {value}")
    return value


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args])


def files(directory):
    result = {}
    for path in directory.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"symlink not allowed: {path}")
        if path.is_file():
            result[path.relative_to(directory).as_posix()] = path.read_bytes()
    return result


def inputs(path):
    result = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"(?:export\s+)?([A-Z0-9_]+)=([^\s#]+)", line)
        if not match:
            raise ValueError(f"invalid input in {path}: {line}")
        key, value = match.groups()
        if key in result:
            raise ValueError(f"duplicate input: {key}")
        result[key] = value
    return result


def check_delay(repo, task, network):
    identifier(task.name, "task identifier")
    identifier(network, "network identifier")
    config = task / "config" / network
    if os.path.lexists(config / "network.env"):
        raise ValueError("network.env is reserved for the archive snapshot")
    values = inputs(config / ".env")
    if "RECORD_STATE_DIFF" in values:
        raise ValueError("RECORD_STATE_DIFF is injected by the signer tool, not a task input")
    for key in ("UPGRADE_ID", "EXPECTED_CURRENT_TIMESTAMP", "NEW_TIMESTAMP"):
        value = values.get(key, "")
        if not re.fullmatch(r"0|[1-9][0-9]*", value):
            raise ValueError(f"invalid {key}")
        limit = (1 << (256 if key == "UPGRADE_ID" else 64)) - 1
        if int(value) > limit:
            raise ValueError(f"invalid {key}: overflow")
    if int(values["NEW_TIMESTAMP"]) <= int(values["EXPECTED_CURRENT_TIMESTAMP"]):
        raise ValueError("NEW_TIMESTAMP must be later than EXPECTED_CURRENT_TIMESTAMP")
    if not re.fullmatch(r"[0-9a-f]{40}", values.get("BASE_CONTRACTS_COMMIT", "")):
        raise ValueError("invalid BASE_CONTRACTS_COMMIT")
    if not (config / "README.md").is_file():
        raise ValueError("missing signer README")
    network_env = repo / "config" / f"{network}.env"
    if not network_env.is_file():
        raise ValueError("missing global network configuration")
    print(f"Prepared {task.name}/config/{network}; canonical files are unchanged")


def check_verifier(repo, task, network):
    identifier(task.name, "task identifier")
    identifier(network, "network identifier")
    config = task / "config" / network
    if os.path.lexists(config / "network.env"):
        raise ValueError("network.env is reserved for the archive snapshot")
    values = inputs(config / ".env")
    if "RECORD_STATE_DIFF" in values:
        raise ValueError("RECORD_STATE_DIFF is injected by the signer tool, not a task input")
    if values.get("BASE_CONTRACTS_COMMIT") != "8c21f6d08a36b4059ae2bb8938f1e7e758a0e962":
        raise ValueError("unsupported BASE_CONTRACTS_COMMIT; requires AggregateVerifier 0.3.0 at the reviewed pin")
    game_type = values.get("GAME_TYPE", "")
    if not re.fullmatch(r"0|[1-9][0-9]*", game_type) or int(game_type) >= 1 << 32:
        raise ValueError("invalid GAME_TYPE")
    fields = {"CURRENT_AGGREGATE_VERIFIER": 40, **{
        f"AGGREGATE_VERIFIER_{name}_HASH": 64 for name in ("TEE_IMAGE", "ZK_RANGE", "ZK_AGGREGATE")
    }}
    for key, length in fields.items():
        value = values.get(key, "")
        if not re.fullmatch(rf"0x[0-9a-fA-F]{{{length}}}", value) or int(value, 16) == 0:
            raise ValueError(f"invalid {key}: expected a nonzero {length // 2}-byte hex value")
    unknown = values.keys() - fields.keys() - {"BASE_CONTRACTS_COMMIT", "GAME_TYPE"}
    if unknown:
        raise ValueError(f"unexpected task inputs: {', '.join(sorted(unknown))}")
    if not (config / "README.md").is_file():
        raise ValueError("missing signer README")
    if not (repo / "config" / f"{network}.env").is_file():
        raise ValueError("missing global network configuration")
    print(f"Prepared {task.name}/config/{network}; canonical files are unchanged")


def archive(repo, task, network, date):
    identifier(task.name, "task identifier")
    identifier(network, "network identifier")
    try:
        if datetime.date.fromisoformat(date).isoformat() != date:
            raise ValueError()
    except ValueError:
        raise ValueError(f"invalid task date: {date}") from None
    if task != repo / "standby/evm/tasks" / task.name:
        raise ValueError("task must be a canonical standby task")
    all_files = files(task)
    invocation_paths = INVOCATION_DIRS | INVOCATION_FILES
    canonical = {name: data for name, data in all_files.items() if name.split("/")[0] not in invocation_paths}
    relative_task = task.relative_to(repo).as_posix()
    try:
        names = git(repo, "ls-tree", "-r", "--name-only", "refs/remotes/origin/main", "--", relative_task).decode().splitlines()
        main = {
            name[len(relative_task) + 1:]: git(repo, "show", f"refs/remotes/origin/main:{name}")
            for name in names
            if name[len(relative_task) + 1:].split("/")[0] not in invocation_paths
        }
    except subprocess.CalledProcessError:
        raise ValueError("cannot read origin/main; fetch main before archiving") from None
    if not main or canonical != main:
        raise ValueError("canonical standby files differ from main")
    configs = task / "config"
    if not (configs / network).is_dir():
        raise ValueError("selected network invocation does not exist")
    networks = []
    for config in configs.iterdir():
        identifier(config.name, "network identifier")
        if not config.is_dir():
            raise ValueError(f"unexpected config artifact: {config}")
        networks.append(config.name)
    data, errors = status.check_task(task, "standby")
    if errors:
        raise ValueError("invocation status is not finalized:\n" + "\n".join(errors))
    for selected, entry in data["networks"].items():
        if entry["step"] not in ("executed", "canceled"):
            raise ValueError(f"network {selected} is not finalized; set status.json step to executed or canceled")
    signatures = task / "signatures"
    if signatures.exists() and any(path.name not in networks for path in signatures.iterdir()):
        raise ValueError("signatures must belong to a configured network")
    destination = repo / "archive/evm" / f"{date}-{task.name}"
    if os.path.lexists(destination):
        raise ValueError(f"archive destination already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".standby-archive-", dir=destination.parent) as staging:
        snapshot = Path(staging) / "task"
        shutil.copytree(task, snapshot)
        shutil.copy2(repo / "active/evm/foundry.toml", snapshot / "foundry.toml")
        for selected in networks:
            network_snapshot = snapshot / "config" / selected / "network.env"
            if network_snapshot.exists():
                raise ValueError("network.env is reserved for the archive snapshot")
            shutil.copy2(repo / "config" / f"{selected}.env", network_snapshot)
        if files(task) != all_files:
            raise ValueError("invocation changed during archive; no source files removed")
        # mkdir refuses even an empty existing destination, unlike rename on POSIX.
        destination.mkdir()
        try:
            shutil.copytree(snapshot, destination, dirs_exist_ok=True)
            archived = files(destination)
            if any(archived.get(name) != data for name, data in all_files.items()):
                raise ValueError("archive artifact verification failed")
        except Exception:
            shutil.rmtree(destination)
            raise
    if files(task) != all_files:
        raise ValueError("invocation changed during archive; archive retained and no source files removed")
    for name in INVOCATION_DIRS:
        source = task / name
        if source.exists():
            shutil.rmtree(source)
    for name in INVOCATION_FILES:
        source = task / name
        if source.exists():
            source.unlink()
    if files(task) != canonical:
        raise ValueError("canonical verification failed after archive")
    print(f"Archived all finalized networks to {destination.relative_to(repo)}; standby canonical files unchanged")


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    for command in ("check-delay", "check-verifier", "archive"):
        target = sub.add_parser(command)
        target.add_argument("--repo", type=Path, required=True)
        target.add_argument("--task", type=Path, required=True)
        target.add_argument("--network", required=True)
        if command == "archive":
            target.add_argument("--date", required=True)
    sub.add_parser("skip-origin").add_argument("validation", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "skip-origin":
            content = json.loads(args.validation.read_text())
            content["skipTaskOriginValidation"] = True
            args.validation.write_text(json.dumps(content, indent=2) + "\n")
        elif args.command == "check-delay":
            check_delay(args.repo.resolve(), args.task.resolve(), args.network)
        elif args.command == "check-verifier":
            check_verifier(args.repo.resolve(), args.task.resolve(), args.network)
        else:
            archive(args.repo.resolve(), args.task.resolve(), args.network, args.date)
    except (ValueError, OSError) as error:
        print(f"standby-task: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
