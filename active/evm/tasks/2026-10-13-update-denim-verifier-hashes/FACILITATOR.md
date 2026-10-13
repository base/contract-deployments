# Update Denim Verifier Hashes — Facilitator Guide

This task redeploys game type 621's `AggregateVerifier` `0.3.0` with new proof program hashes and
registers it in the `DisputeGameFactory`. The three hashes are constructor immutables, so they cannot
be changed on the existing verifier.

The Denim upgrade task registered `0.3.0` with the hashes of base/base `v1.5.0-rc.6`, whose provers
sample intermediate roots at a hardcoded 300 blocks. `0.3.0` expects 30 for games that start before
Denim, so those proofs are rejected. base/base#5794 makes the provers use each game's interval. It
changes the enclave image and the ZK range and aggregation programs, hence the new hashes.

Replace `<network>` with the rollout network (`zeronet`). Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory
(`active/evm/tasks/2026-10-13-update-denim-verifier-hashes/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT`, the commit the current verifier was deployed
from. The task deploys only `AggregateVerifier` from it.

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `CURRENT_AGGREGATE_VERIFIER` is the verifier currently registered for game type 621 (version `0.3.0`).
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH` is keccak256 of the PCR0 printed by the enclave build of the
  base-proofs PR that deploys the new provers.
- `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` are the SP1 vkeys of
  the same base/base commit.

The deploy script refuses to run while any hash is blank or equal to the current verifier's. Every
other constructor argument, including both proposal interval pairs, is copied from the current
verifier at deploy time.

## 3. Deploy and verify

```bash
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify
```

`deploy` builds with 999999 optimizer runs and no bytecode hash, matching base/contracts' settings
for `AggregateVerifier`. It checks every immutable of the new verifier and writes
`aggregateVerifier` and its constructor arguments to `config/<network>/addresses.json`.

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts, then fill in the new
verifier address in `config/<network>/README.md`.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`.
Replace any generated `<<ContractName>>` or `<<Summary>>` placeholders with reviewed contract names
and state-change descriptions. Expected state changes:

- `DisputeGameFactory`: `gameImpls[621]` moves from `CURRENT_AGGREGATE_VERIFIER` to the new verifier.
- Safe nonce and approval changes.

For any non-mainnet rollout, remove each generated `taskOriginConfig` and add this root field:

```json
"skipTaskOriginValidation": true
```

Commit them and share `config/<network>/README.md` with signers.

## 5. Collect signatures and execute

The `DisputeGameFactory` owner is the 2-of-2 ProxyAdmin owner Safe of the Base multisig and the
Security Council, so each approves its own nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

After execution the script checks that the factory points at the new verifier, that the game count
and game args are unchanged, and that the new verifier still matches the current one on every
immutable but the three hashes. Set the README status to the execution transaction link.

Deploy the new provers right after execution and wipe the prover-service database: rows stored in
the old format no longer deserialize. Games created before execution stay bound to the current
verifier and its hashes.
