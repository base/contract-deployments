# Delay Cobalt Activation to 20:00 UTC — Facilitator Guide

Replace `<network>` with the rollout network, for example `zeronet`. Run every command from
`active/evm/tasks/2026-09-16-delay-cobalt-activation-to-2000/`.

The prerequisite Zeronet delay to 18:00 UTC has
[executed](https://hoodi.etherscan.io/tx/0x8a66d2beda49f48113d1bcc324eb24f0ca186320b515551a12e3777f0b5d8591).

For Zeronet, this task must execute strictly before **September 16, 2026 at 17:00 UTC**. At that
time the existing 18:00 UTC activation enters the registry's one-hour freeze window and can no
longer be changed.

## 1. Review the config

Confirm `config/<network>/.env` contains:

- the deployed `ProtocolVersions` proxy;
- Cobalt upgrade id 12 moving from `1789581600` (18:00 UTC) to `1789588800` (20:00 UTC); and
- the incident multisig matching the registry's `incidentResponder`.

The script refuses to build calls unless the live incident responder, current activation, schedule
length, and schedule commitment all match these inputs.

## 2. Generate validation files

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> gen-validation-cb
```

This creates `config/<network>/validations/base-signer.json`. For Zeronet, remove the generated
`taskOriginConfig` and add `"skipTaskOriginValidation": true` at the JSON root before committing
the file.

## 3. Approve and execute

```bash
SIGNATURES=<concatenated base signatures> make TASK_NETWORK=<network> execute
```

After execution, confirm `getSchedule()[12]` is `1789588800`, then link the transaction from
`config/<network>/README.md`.
