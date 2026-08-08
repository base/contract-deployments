# Active EVM Tasks

Each task supplies only task-specific configuration. Reusable Solidity lives in
`../script/common/`, and reusable signing/execution targets live in `../make/`.

```text
tasks/<task-id>/
├── Task.mk
├── FACILITATOR.md
└── config/<network>/
    ├── .env
    ├── network.env
    ├── README.md
    ├── validations/
    └── funding.json or OwnerDiff.json  # only when required
```

Forge writes execution artifacts directly into the task directory, grouped by
script and chain ID. This keeps everything needed to archive a task under
`tasks/<task-id>/` without another `records/` layer.

`Task.mk` selects an operation and may set a default network. Standard
operations provide their own `SCRIPT_NAME`; custom tasks define it locally.

```makefile
OPERATION := gas
GAS_MODE := combined
TASK_NETWORK ?= mainnet
```

Gas tasks set `GAS_MODE` to `gas-only` or `combined`.

| Operation | Required task inputs | Reusable targets |
| --- | --- | --- |
| `funding` | `OWNER_SAFE`, `SENDER`, `funding.json` | `gen-validation`, `execute` |
| `gas` / `gas-only` | `OWNER_SAFE`, `SYSTEM_CONFIG`, `SENDER`, `OLD_GAS_LIMIT`, `NEW_GAS_LIMIT` | `gen-validation`, `sign-upgrade`, `execute-upgrade`, `gen-validation-rollback`, `sign-rollback`, `execute-rollback` |
| `gas` / `combined` | Gas-only inputs plus old/new elasticity and DA footprint scalar | Gas-only targets plus `da-scalar` |
| `safe-management` | `OWNER_SAFE`, `SENDER`, `OwnerDiff.json` | `gen-validation`, `execute` |
| `bridge-threshold` | Safe, portal, validator, sender, and new threshold | `gen-validation`, `execute` |
| `pause-bridge` | Safe, portal, L2 bridge, and sender | `gen-validation`, `sign-pause`, `sign-unpause`, `execute-pause`, `execute-unpause`, `check-status` |
| `superchain-pause` | Incident multisig, SystemConfig, and sender | `gen-validation`, `sign-pause`, `execute-pause`, `check-status`, `check-nonce` |
| `custom` | Defined by the task | Defined in `Task.mk` |

Create the files above, then run the task from the repository root:

```bash
make -C active/evm TASK_ID=<task-id> TASK_NETWORK=<network> deps
make -C active/evm TASK_ID=<task-id> TASK_NETWORK=<network> gen-validation
```

Task inputs belong in `config/<network>/.env`, including
`BASE_CONTRACTS_COMMIT` and `RECORD_STATE_DIFF=true`. Start the signer README at
`READY TO SIGN`, use simple validation names, and include task-specific
generation, approval, and execution steps in `FACILITATOR.md`.

Keep RPC URLs, chain IDs, Ledger account, Safe addresses, and shared contract
addresses in `network.env`; keep operation-specific values and JSON paths in
`.env`.
