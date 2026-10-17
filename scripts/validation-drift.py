#!/usr/bin/env python3
"""Check task input fingerprints offline and compare regenerated signer validations."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import sys


HINT = "Regenerate with the task's gen-validation targets on an internal machine, then review the diff."
DEPENDENCY_DIRS = {"lib", "node_modules", "vendor", "dependencies"}
ANNOTATED_SECTIONS = {"stateOverrides", "stateChanges", "balanceChanges"}


def read_json(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path}: validation must be a JSON object")
    return data


def repo_for_task(task):
    for parent in task.parents:
        if (parent / ".git").exists():
            return parent
    raise ValueError(f"{task}: cannot find repository root")


def declared_files(task):
    text = (task / "Makefile").read_text(encoding="utf-8").replace("\\\n", "")
    text = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("#"))
    files = set()
    for match in re.finditer(r"\$\(\s*call\s+GEN_VALIDATION\s*,", text):
        args, current, depth = [], [], 0
        for char in text[match.end():]:
            if char == ")" and depth == 0:
                args.append("".join(current).strip())
                break
            if char == "," and depth == 0:
                args.append("".join(current).strip())
                current = []
                continue
            if char in "({":
                depth += 1
            elif char in ")}":
                depth -= 1
            current.append(char)
        if len(args) < 4 or not re.fullmatch(r"[A-Za-z0-9_.-]+\.json", args[3]):
            raise ValueError(f"{task / 'Makefile'}: GEN_VALIDATION needs a literal signer JSON filename as its fourth argument")
        files.add(args[3])
    return files


def without_comments(text):
    # Keep quoted import paths intact while removing commented-out imports.
    return re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*.*?\*/',
                  lambda m: " " if m[0].startswith(("//", "/*")) else m[0], text, flags=re.S)


def remappings(project):
    mappings = {}
    config = project / "foundry.toml"
    if config.exists():
        text = without_comments(config.read_text(encoding="utf-8"))
        for block in re.findall(r"\bremappings\s*=\s*\[(.*?)\]", text, re.S):
            for mapping in re.findall(r'["\']([^"\']+)["\']', block):
                prefix, target = mapping.split("=", 1)
                mappings[prefix] = target
    path = project / "remappings.txt"
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                prefix, target = line.split("=", 1)
                mappings[prefix] = target
    return sorted(mappings.items(), key=lambda pair: len(pair[0]), reverse=True)


def script_entrypoint(project, cmd):
    if not isinstance(cmd, str):
        raise ValueError("validation must have a Forge script cmd")
    tokens = shlex.split(cmd)
    for index in range(len(tokens) - 1):
        if tokens[index:index + 2] == ["forge", "script"]:
            for token in tokens[index + 2:]:
                if not token.startswith("-") and re.fullmatch(r"[^:]+\.sol(?::[^/:]+)?", token):
                    return (project / token.split(":", 1)[0]).resolve()
            break
    raise ValueError("cmd must contain a Forge script .sol path")


def fingerprint(repo, task, network, cmd):
    if not re.fullmatch(r"[a-z0-9-]+", network):
        raise ValueError("invalid network identifier")
    project = task if (task / "foundry.toml").is_file() else repo / "active/evm"
    config = task / "config" / network
    paths = {task / "Makefile", config / ".env", repo / "config" / f"{network}.env"}
    paths.update(p for p in config.rglob("*")
                 if p.is_file() and p != config / "README.md" and p.relative_to(config).parts[0] != "validations")
    paths.add(script_entrypoint(project, cmd))
    paths.update(p for p in (task / "script").rglob("*") if p.is_file())
    pending = [p for p in paths if p.suffix == ".sol"]
    visited = set()
    mappings = remappings(project)
    while pending:
        source = pending.pop().resolve()
        if source in visited:
            continue
        visited.add(source)
        text = without_comments(source.read_text(encoding="utf-8"))
        for statement in re.findall(r"\bimport\s+[^;]+;", text):
            match = re.search(r'["\']([^"\']+)["\']', statement)
            if not match:
                raise ValueError(f"{source}: cannot parse import {statement}")
            name = match[1]
            if name.startswith("."):
                imported = source.parent / name
            else:
                imported = project / name
                for prefix, target in mappings:
                    if name.startswith(prefix):
                        imported = project / target / name[len(prefix):]
                        break
            imported = imported.resolve()
            try:
                relative = imported.relative_to(repo)
            except ValueError:
                raise ValueError(f"{source}: import {name} resolves outside the repository") from None
            if DEPENDENCY_DIRS.intersection(relative.parts):
                continue
            if not imported.is_file():
                raise ValueError(f"{source.relative_to(repo)}: unresolved import {name}")
            paths.add(imported)
            pending.append(imported)
    files = {p.relative_to(repo).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
    files = dict(sorted(files.items()))
    # The digest uses compact UTF-8 JSON of the sorted [path, sha256] pairs.
    payload = json.dumps(list(files.items()), ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return {"algorithm": "sha256", "digest": hashlib.sha256(payload).hexdigest(), "files": files}


def stamp(args):
    task = args.task_dir.resolve()
    if not (task / "Makefile").is_file() or not (task / "config" / args.network).is_dir():
        print(f"Skipped stamping {task}: layout is not supported by the fingerprint check")
        return 0
    repo = repo_for_task(task)
    for path in args.files:
        data = read_json(path)
        data["taskInputs"] = fingerprint(repo, task, args.network, data.get("cmd"))
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Stamped {path}")
    return 0


def check(args):
    repo = args.repo.resolve()
    errors = []
    for tree in ("active", "standby"):
        for task in sorted((repo / tree / "evm/tasks").glob("*/")):
            if not (task / "Makefile").is_file():
                print(f"Skipped {task.relative_to(repo)}: layout is not supported by the fingerprint check")
                continue
            try:
                declared = declared_files(task)
            except (OSError, ValueError) as error:
                errors.append(str(error))
                continue
            for config in sorted((task / "config").glob("*/")):
                label = f"{task.relative_to(repo).as_posix()}/{config.name}"
                readme = config / "README.md"
                if readme.exists() and re.search(r"^\s*Status:\s*\[?(EXECUTED|CANCELED)\b", readme.read_text(encoding="utf-8"), re.I | re.M):
                    print(f"Skipped {label}: EXECUTED or CANCELED")
                    continue
                validations = config / "validations"
                if not (config / ".env").is_file():
                    if readme.exists() or validations.exists():
                        errors.append(f"{label}: missing .env")
                    continue
                present = {path.name for path in validations.glob("*.json")}
                errors.extend(f"{label}: missing validation {name}" for name in sorted(declared - present))
                errors.extend(f"{label}: undeclared validation {name}" for name in sorted(present - declared))
                for name in sorted(declared & present):
                    label_file = f"{label}/validations/{name}"
                    try:
                        data = read_json(validations / name)
                        recorded = data.get("taskInputs")
                        if not isinstance(recorded, dict) or not isinstance(recorded.get("files"), dict):
                            errors.append(f"{label_file}: missing or invalid taskInputs")
                            continue
                        inputs = fingerprint(repo, task, config.name, data.get("cmd"))
                        if recorded != inputs:
                            errors.append(f"{label_file}: taskInputs fingerprint mismatch")
                            old, new = recorded["files"], inputs["files"]
                            for path in sorted(old.keys() | new.keys()):
                                if path not in old:
                                    errors.append(f"  added: {path}")
                                elif path not in new:
                                    errors.append(f"  removed: {path}")
                                elif old[path] != new[path]:
                                    errors.append(f"  changed: {path}")
                    except (OSError, ValueError) as error:
                        errors.append(f"{label_file}: {error}")
    if errors:
        print("\n".join(errors))
        print(HINT)
        return 1
    print("Validation input fingerprints match.")
    return 0


def differences(committed, regenerated, path="$", annotated=False, collection=None):
    if isinstance(committed, dict) and isinstance(regenerated, dict):
        ignored = {"name", "description", "allowDifference"} if annotated else set()
        if path == "$":
            ignored.add("taskOriginConfig")
        if annotated and committed.get("allowDifference") is True:
            ignored.update({"before", "after", "value"})
        for key in sorted((committed.keys() | regenerated.keys()) - ignored):
            child = f"{path}.{key}"
            if key not in committed:
                yield f"{child}: added {json.dumps(regenerated[key], ensure_ascii=False)}"
            elif key not in regenerated:
                yield f"{child}: removed {json.dumps(committed[key], ensure_ascii=False)}"
            else:
                section = path == "$" and key in ANNOTATED_SECTIONS
                yield from differences(committed[key], regenerated[key], child, annotated or section,
                                       key if section or (annotated and key in {"changes", "overrides"}) else None)
    elif isinstance(committed, list) and isinstance(regenerated, list):
        identity = "address" if collection in ANNOTATED_SECTIONS else "key" if collection in {"changes", "overrides"} else None
        if identity and all(isinstance(item, dict) and identity in item for item in committed + regenerated):
            left = {item[identity]: item for item in committed}
            right = {item[identity]: item for item in regenerated}
            if len(left) != len(committed) or len(right) != len(regenerated):
                yield f"{path}: duplicate {identity} entries"
                return
            for key in sorted(left.keys() | right.keys()):
                child = f"{path}[{identity}={json.dumps(key)}]"
                if key not in left:
                    yield f"{child}: added entry"
                elif key not in right:
                    yield f"{child}: removed entry"
                else:
                    yield from differences(left[key], right[key], child, annotated)
        else:
            for index in range(max(len(committed), len(regenerated))):
                child = f"{path}[{index}]"
                if index >= len(committed):
                    yield f"{child}: added entry"
                elif index >= len(regenerated):
                    yield f"{child}: removed entry"
                else:
                    yield from differences(committed[index], regenerated[index], child, annotated)
    elif type(committed) is not type(regenerated) or committed != regenerated:
        yield f"{path}: {json.dumps(committed, ensure_ascii=False)} -> {json.dumps(regenerated, ensure_ascii=False)}"


def compare(args):
    changes = list(differences(read_json(args.committed), read_json(args.regenerated)))
    if changes:
        print(f"{args.committed} vs {args.regenerated}:")
        print("\n".join(changes))
        print(HINT)
        return 1
    print(f"No meaningful differences: {args.committed.name}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    stamping = commands.add_parser("stamp")
    stamping.add_argument("--task-dir", type=Path, required=True)
    stamping.add_argument("--network", required=True)
    stamping.add_argument("files", type=Path, nargs="+")
    stamping.set_defaults(func=stamp)
    checking = commands.add_parser("check")
    checking.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    checking.set_defaults(func=check)
    comparison = commands.add_parser("compare")
    comparison.add_argument("committed", type=Path)
    comparison.add_argument("regenerated", type=Path)
    comparison.set_defaults(func=compare)
    args = parser.parse_args()
    try:
        return args.func(args)
    except (OSError, ValueError) as error:
        print(f"validation-drift: {error}", file=sys.stderr)
        print(HINT, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
