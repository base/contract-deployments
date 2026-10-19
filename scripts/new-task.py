#!/usr/bin/env python3
import argparse
import datetime
import importlib.util
import os
from pathlib import Path
import re
import shutil
import sys

spec = importlib.util.spec_from_file_location("task_status", Path(__file__).with_name("task-status.py"))
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)

MAKEFILE = """include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required on the command line, e.g. make TASK_NETWORK=<network> $(MAKECMDGOALS))
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK must not be empty)
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)
TASK_DIR := tasks/@TASK@

.DEFAULT_GOAL := help
.PHONY: help
help:
\t@echo 'Implement the task scripts and targets before generating validations. See FACILITATOR.md.'

# Enable these targets only after setting SCRIPT_NAME, SENDER, and the Safe addresses for this operation.
# gen-validation: deps-signer-tool
#\t$(call GEN_VALIDATION,$(SCRIPT_NAME),$(SAFE),$(SENDER),base-signer.json,)
# approve:
#\t$(call MULTISIG_APPROVE,$(SAFE),$(SIGNATURES))
# execute:
#\t$(call MULTISIG_EXECUTE,$(SIGNATURES))
"""

FACILITATOR = """# Task facilitator guide

Run commands from this task directory. Replace `<network>` with the rollout network and pass `TASK_NETWORK=<network>` on every Make command line. Exported values and defaults are not accepted.

## Author and review

Implement the task-specific scripts and enable the validation, approval, and execution targets in the Makefile before using them. Store one-off scripts in `script/`. Review `config/<network>/.env`, fill in `BASE_CONTRACTS_COMMIT` and the operation's inputs, and replace the description in `config/<network>/README.md`. Keep this guide network-agnostic.

```sh
make TASK_NETWORK=<network> deps
```

Select a reviewed contracts commit before running `deps`; `forge-deps` rejects an empty pin. Review the scripts, configuration, ownership, and expected onchain changes. Keep the task-root `status.json` current as authoring, validation, and review progress.

## Generate validation files

After implementing the targets, generate and inspect `config/<network>/validations/base-signer.json` and any other required signer validations. Name validation files after signer roles, such as `security-council-signer.json`. Check the full simulated state diff and replace generated summary placeholders. Collect task-origin signatures only for mainnet scripts that go through the ProxyAdmin owner. Task-origin signing covers `config/<network>/`, never the root `status.json`.

```sh
make TASK_NETWORK=<network> gen-validation
```

Commit the reviewed configuration and validation files before asking signers to sign. Set the network step to `ready_to_sign`, then `collecting`, and update signature counts in `status.json` as signatures arrive. Signers use the network README's Sign section and send signatures to the facilitator.

## Approve and execute

Confirm each Safe's live threshold and nonce. Collect signatures in Safe owner-address order. Revalidate changed inputs and recollect signatures if the transaction hash changes. Once all required approvals are ready, set the step to `ready_to_execute`.

```sh
make TASK_NETWORK=<network> approve SIGNATURES=<concatenated-signatures>
make TASK_NETWORK=<network> execute SIGNATURES=<concatenated-signatures>
```

Check the execution state against the signed validation. Commit all final artifacts, including task-scoped Forge `records/`, network-specific addresses and validations, and signatures. Finalize `config/<network>/README.md` with `Status: EXECUTED` and its transaction link, or `Status: CANCELED` with a reason. Update the matching step, execution transaction, and `last_updated` in the root `status.json` in the same change.

## Archive

Keep the task active until every intended network is executed or canceled and all final artifacts are committed. Do not archive between network rollouts. From the repository root, run `make check-task-status`, then `make archive-task` and select this task. Historical archives must not be edited or executed.
"""


def identifier(value, label):
    if not status.IDENTIFIER.fullmatch(value):
        raise ValueError(f"invalid {label}: {value}")
    return value


def iso_date(value):
    try:
        if datetime.date.fromisoformat(value).isoformat() == value:
            return value
    except ValueError:
        pass
    raise ValueError(f"invalid TASK_DATE: {value}")


def scaffold(repo, slug, task_id, operation, network, date):
    if sum(bool(value) for value in (slug, task_id, operation)) != 1:
        raise ValueError("provide exactly one of TASK_SLUG, TASK_ID, or STANDBY_OP")
    identifier(network, "TASK_NETWORK")
    if not (repo / "config" / f"{network}.env").is_file():
        raise ValueError(f"missing global network configuration: config/{network}.env")
    date = iso_date(date or datetime.date.today().isoformat())
    if slug:
        identifier(slug, "TASK_SLUG")
        task = repo / "active/evm/tasks" / f"{date}-{slug}"
        if os.path.lexists(task):
            raise ValueError(f"task already exists: {task}")
    elif task_id:
        match = re.fullmatch(r"([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)", task_id)
        if match:
            iso_date(match.group(1))
            identifier(match.group(2), "TASK_ID")
        else:
            identifier(task_id, "TASK_ID")
        task = repo / "active/evm/tasks" / task_id
        if not task.is_dir() or task.is_symlink():
            raise ValueError(f"TASK_ID must name an existing active task: {task_id}")
    else:
        identifier(operation, "STANDBY_OP")
        task = repo / "standby/evm/tasks" / operation
        if not task.is_dir() or task.is_symlink():
            raise ValueError(f"STANDBY_OP must name an existing standby operation: {operation}")
    config = task / "config" / network
    if os.path.lexists(config):
        raise ValueError(f"network config already exists: {config}")
    data = None if slug else status.updated_status(task, network)
    if data is not None and set(data["networks"]) - {network} != status.config_networks(task):
        raise ValueError(f"{task / 'status.json'}: adopt existing config networks before adding another")
    created = []
    try:
        if slug:
            task.mkdir(parents=True)
            created.append(task)
            data = status.updated_status(task, network)
            (task / "Makefile").write_text(MAKEFILE.replace("@TASK@", task.name))
            (task / "FACILITATOR.md").write_text(FACILITATOR)
            (task / "script").mkdir()
            (task / "script/.gitkeep").touch()
        config.mkdir(parents=True)
        if not slug:
            created.append(config)
        (config / ".env").write_text("BASE_CONTRACTS_COMMIT=\n")
        readme = f"# {task.name}\n\nStatus: READY TO SIGN\n\n## Description\n\n<Describe the operation on {network}, its targets, and expected changes.>\n"
        if operation:
            readme += "\nFacilitator instructions: [FACILITATOR.md](../../FACILITATOR.md).\n"
        readme += f"\n## Sign\n\nFrom the repository root:\n\n```sh\nmake TASK_NETWORK={network} sign-task\n```\n\nSelect `{task.name}` for {network}, sign, and send the signature to the facilitator.\n"
        (config / "README.md").write_text(readme)
        status.write_status(task, data)
    except Exception:
        for path in reversed(created):
            shutil.rmtree(path)
        raise
    for path in sorted(task.rglob("*")) if slug else (config / ".env", config / "README.md", task / "status.json"):
        if path.is_file():
            print(f"Created or updated {path.relative_to(repo)}")
    print(f"Next: follow {task.relative_to(repo)}/FACILITATOR.md, fill in config/{network}/.env and README.md, and keep status.json current. Run make check-task-status.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    for flag in ("slug", "task-id", "standby-op", "network", "date"):
        variable = {"slug": "TASK_SLUG", "task-id": "TASK_ID", "standby-op": "STANDBY_OP", "network": "TASK_NETWORK", "date": "TASK_DATE"}[flag]
        parser.add_argument(f"--{flag}", default=os.environ.get(variable, ""))
    args = parser.parse_args()
    try:
        scaffold(args.repo.resolve(), args.slug, args.task_id, args.standby_op, args.network, args.date)
    except (OSError, ValueError) as error:
        print(f"new-task: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
