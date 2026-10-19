#!/usr/bin/env python3
import argparse
import datetime
import json
from pathlib import Path
import re
import sys

IDENTIFIER = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*\Z")
SCHEMA = Path(__file__).with_name("task-status.schema.json")
FINAL_STATUS = re.compile(r"(EXECUTED|CANCELED)(?:\s+https?://\S+)?|\[(EXECUTED|CANCELED)\]\(https?://[^\s)]+\)")
FINAL_STATUS_PREFIX = re.compile(r"EXECUTED|CANCELED|\[(?:EXECUTED|CANCELED)\]", re.IGNORECASE)


def validate(value, schema, location="$"):
    types = {
        "object": lambda v: isinstance(v, dict),
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: type(v) is int,
        "null": lambda v: v is None,
    }
    expected = schema.get("type", [])
    if isinstance(expected, str):
        expected = [expected]
    if expected and not any(types[name](value) for name in expected):
        return [f"{location}: expected {' or '.join(expected)}"]
    errors = []
    if "const" in schema and value != schema["const"]:
        errors.append(f"{location}: expected constant {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{location}: expected one of {schema['enum']!r}")
    if isinstance(value, str) and "pattern" in schema:
        pattern = schema["pattern"]
        if pattern.endswith("$"):
            pattern = pattern[:-1] + r"\Z"
        if not re.search(pattern, value):
            errors.append(f"{location}: does not match pattern {schema['pattern']!r}")
    if type(value) is int and "minimum" in schema and value < schema["minimum"]:
        errors.append(f"{location}: must be >= {schema['minimum']}")
    if isinstance(value, dict):
        if len(value) < schema.get("minProperties", 0):
            errors.append(f"{location}: requires at least {schema['minProperties']} properties")
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{location}.{key}: missing required property")
        properties = schema.get("properties", {})
        additional = schema.get("additionalProperties", True)
        for key, item in value.items():
            child = f"{location}.{key}"
            if "propertyNames" in schema:
                errors.extend(validate(key, schema["propertyNames"], child))
            if key in properties:
                errors.extend(validate(item, properties[key], child))
            elif additional is False:
                errors.append(f"{child}: unknown field")
            elif isinstance(additional, dict):
                errors.extend(validate(item, additional, child))
    return errors


def read_status(path, task, kind):
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        return None, [f"{path}: missing status.json"]
    except (OSError, ValueError) as error:
        return None, [f"{path}: {error}"]
    errors = validate(data, json.loads(SCHEMA.read_text()), "$")
    if isinstance(data, dict):
        if data.get("task") != task:
            errors.append(f"$.task: must equal directory name {task!r}")
        if data.get("kind") != kind:
            errors.append(f"$.kind: must be {kind!r}")
    return data, [f"{path}: {error}" for error in errors]


def config_networks(task):
    config = task / "config"
    return {path.name for path in config.iterdir() if path.is_dir()} if config.is_dir() else set()


def check_task(task, kind):
    errors = []
    path = task / "status.json"
    networks = config_networks(task)
    for misplaced in sorted((task / "config").rglob("status.json")):
        errors.append(f"{misplaced}: status.json must be at the task root, outside config/")
    if kind == "standby" and not networks:
        if path.exists():
            errors.append(f"{path}: standby operation with no invocation must not have status.json")
        return None, errors
    data, invalid = read_status(path, task.name, kind)
    errors.extend(invalid)
    if invalid:
        return data, errors
    if set(data["networks"]) != networks:
        errors.append(f"{path}: networks must match config directories {sorted(networks)!r}")
    for network, entry in data["networks"].items():
        step = entry["step"]
        if (step == "executed") != (entry["executed_tx"] is not None):
            errors.append(f"{path}: networks.{network}.executed_tx must be non-null if and only if step is executed")
        readme = task / "config" / network / "README.md"
        try:
            lines = readme.read_text().splitlines()[:20] if readme.is_file() else []
        except OSError as error:
            errors.append(f"{readme}: {error}")
            continue
        statuses = [line.removeprefix("Status:").strip() for line in lines if line.startswith("Status:")]
        if any(FINAL_STATUS_PREFIX.match(value) and not FINAL_STATUS.fullmatch(value) for value in statuses):
            errors.append(f"{readme}: expected EXECUTED or CANCELED, optionally followed by an HTTP(S) URL, "
                          "or [EXECUTED](<url>) or [CANCELED](<url>) with an HTTP(S) URL")
            continue
        finals = [match for value in statuses if (match := FINAL_STATUS.fullmatch(value))]
        final = (finals[0].group(1) or finals[0].group(2)).lower() if len(statuses) == len(finals) == 1 else None
        if (finals or step in ("executed", "canceled")) and final != step:
            errors.append(f"{readme}: finalized Status must match status.json step {step!r}")
    return data, errors


def check(repo):
    errors = []
    for kind in ("active", "standby"):
        tasks = repo / kind / "evm/tasks"
        for task in sorted(tasks.iterdir()) if tasks.is_dir() else []:
            if task.is_dir():
                _, invalid = check_task(task, kind)
                errors.extend(invalid)
    return errors


def task_identity(task):
    if not task.is_dir() or task.parent.name != "tasks" or task.parent.parent.name != "evm" or task.parent.parent.parent.name not in ("active", "standby"):
        raise ValueError(f"{task}: expected an existing active or standby task directory")
    return task.parent.parent.parent.name


def updated_status(task, network):
    if not IDENTIFIER.fullmatch(network):
        raise ValueError(f"invalid network identifier: {network}")
    kind = task_identity(task)
    path = task / "status.json"
    if path.exists():
        data, errors = read_status(path, task.name, kind)
        if errors:
            raise ValueError("\n".join(errors))
    else:
        data = {"schema_version": 1, "task": task.name, "kind": kind, "networks": {}}
    if network in data["networks"]:
        raise ValueError(f"{path}: network {network} already exists")
    data["networks"][network] = {
        "step": "authoring", "pr": None, "blocksec_ticket": None,
        "signatures": {}, "executed_tx": None,
    }
    data["last_updated"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    errors = validate(data, json.loads(SCHEMA.read_text()), "$")
    if errors:
        raise ValueError("\n".join(f"{path}: {error}" for error in errors))
    return data


def write_status(task, data):
    (task / "status.json").write_text(json.dumps(data, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    checker = sub.add_parser("check")
    checker.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    add = sub.add_parser("add-network")
    add.add_argument("task_dir", type=Path)
    add.add_argument("network")
    args = parser.parse_args()
    try:
        if args.command == "check":
            errors = check(args.repo.resolve())
            if errors:
                print("\n".join(errors), file=sys.stderr)
                return 1
            print("Task statuses are valid")
        else:
            task = args.task_dir.resolve()
            write_status(task, updated_status(task, args.network))
            print(f"Updated {task / 'status.json'}")
    except (OSError, ValueError) as error:
        print(f"task-status: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
