# Update Cobalt Verifier Hashes — Facilitator Guide

Replace `<network>` with the rollout network, for example `zeronet`. Run every command from
`active/evm/tasks/2026-09-16-update-cobalt-verifier-hashes/`.

The three proof program hashes are constructor immutables, so this task deploys a new
`AggregateVerifier` and registers it for game type 621. It does not modify existing games.

## 1. Fill and review the config

Set these values in `config/<network>/.env`:

- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`
- `AGGREGATE_VERIFIER_ZK_RANGE_HASH`
- `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH`

Confirm `OLD_AGGREGATE_VERIFIER` is still registered for game type 621. The scripts stop if it
changed, any new hash is zero, or all three new hashes match the current verifier.

## 2. Install dependencies and deploy

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> deploy
make TASK_NETWORK=<network> verify VERIFIER_API_KEY=<key>
```

The deploy script copies every constructor value except the three proof program hashes from the
live verifier. It writes the new address and encoded constructor arguments to
`config/<network>/addresses.json`. Commit that file and the task-scoped `records/` artifacts.

## 3. Generate validation files

```bash
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

After execution, confirm `gameImpls(621)` returns the new verifier and its three proof program hash
getters return the configured values. Then link the transaction from `config/<network>/README.md`.
