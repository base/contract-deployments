# Deploy ProtocolVersions — Facilitator Guide

This task deploys and initializes the Base `ProtocolVersions` registry. Replace `<network>` in the
commands below; every command requires `TASK_NETWORK` explicitly. Run them from this directory.

## 1. Review the network config

Confirm `config/<network>/.env` against the node chain config, especially the ordered activation
schedule, minimum protocol version, and incident responder. Mainnet imports its history through
Beryl and schedules Cobalt at ID 12 for September 30, 2026 at 18:00 UTC (`1790791200`).

## 2. Install dependencies and deploy

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> deploy
make TASK_NETWORK=<network> verify VERIFIER_API_KEY=<key>
```

The proxy uses 5,000 optimizer runs and the implementation uses 999,999, matching the pinned
`base/contracts` build. Commit `config/<network>/addresses.json` and the `records/` artifacts.

## 3. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These create `config/<network>/validations/base-signer.json` and
`security-council-signer.json`. Do not generate them until the deployed addresses are final.

## 4. Generate mainnet task-origin signatures

After all task files and validations are final:

```bash
make TASK_NETWORK=mainnet sign-as-task-creator
make TASK_NETWORK=mainnet sign-as-base-facilitator
make TASK_NETWORK=mainnet sign-as-sc-facilitator
```

Commit the generated files under `signatures/mainnet/`.

## 5. Collect approvals and execute

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

The transaction calls `ProxyAdmin.upgradeAndCall` once, setting the implementation and initializing
the schedule, minimum protocol version, and incident responder atomically. The script verifies the
proxy admin, implementation version, complete schedule, and derived schedule commitment before and
after execution.
