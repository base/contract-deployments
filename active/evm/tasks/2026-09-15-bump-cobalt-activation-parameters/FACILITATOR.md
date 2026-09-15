# Bump Cobalt Activation Parameters — Facilitator Guide

Replace `<network>` with the rollout network, for example `zeronet`. Run every command from
`active/evm/tasks/2026-09-15-bump-cobalt-activation-parameters/`.

## 1. Confirm the Cobalt upgrade prerequisite

`2026-09-14-cobalt-upgrade` must execute first. For Zeronet, it has
[executed](https://hoodi.etherscan.io/tx/0xabfb3ed6b24334891957b4f0c22273b06392132288862ca8235b13af0a47d667)
and initialized the `ProtocolVersions` proxy at `0x30e172aaC675c9fe5A64792F92C9fD4d3E7cA9Da`.

For Zeronet, this task must execute strictly before **September 16, 2026 at 15:00 UTC**. At that
time the existing 16:00 UTC activation enters the registry's one-hour freeze window and can no
longer be changed.

## 2. Review the config

Confirm `config/<network>/.env` contains:

- the deployed `ProtocolVersions` proxy;
- Cobalt upgrade id 12 moving from `1789574400` (16:00 UTC) to `1789581600` (18:00 UTC); and
- the packed minimum protocol version moving from v1.3.2 to v1.4.0.

The script refuses to build calls unless the live owner, current activation, current minimum
version, schedule length, and schedule commitment all match these inputs.

## 3. Review the validation files

The Zeronet validation files are committed under `config/zeronet/validations/`. Regenerate them
after any config, script, or relevant onchain state change:

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These create `config/<network>/validations/base-signer.json` and
`security-council-signer.json`. For Zeronet, remove the generated `taskOriginConfig` and add
`"skipTaskOriginValidation": true` at the JSON root before committing the files.

## 4. Approve and execute

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

After execution, confirm `getSchedule()[12]` is `1789581600` and `minimumProtocolVersion()` is
`79228162588051313888382156800`, then link the transaction from `config/<network>/README.md`.
