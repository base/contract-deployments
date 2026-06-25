# Active EVM Tasks

Active EVM tasks live under `tasks/<task-id>/`. Shared Foundry setup and reusable scripts stay at this `active/evm` root so multiple active tasks can use the same `script/common/<category>/` implementations.

## Layout

```text
active/evm/
  foundry.toml
  Makefile
  script/common/
  tasks/
    2026-06-18-beryl-1/
      README.md
      FACILITATOR.md
      addresses.json
      config/<network>/
        .env
        network.env
        validations/
        signatures/
    2026-06-18-beryl-2/
      ...
```

## Running A Task

Run task commands from `active/evm` and select the task with `TASK_ID`:

```bash
cd active/evm
TASK_ID=2026-06-18-beryl-1 TASK_NETWORK=mainnet make gen-validation-update-verifier-hashes-cb
```

The root Makefile runs Forge from `active/evm`, while task-specific files are read from `tasks/<task-id>/`. Common scripts that need task-local artifacts receive paths through environment variables such as `ADDRESSES_JSON=tasks/<task-id>/addresses.json`.

## Demo Tasks

`2026-06-18-beryl-1` and `2026-06-18-beryl-2` are duplicated from the same Beryl task so the signer UI can exercise multiple active task discovery on this branch.
