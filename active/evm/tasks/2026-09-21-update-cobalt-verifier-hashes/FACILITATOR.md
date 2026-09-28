# Update Cobalt Verifier Hashes — Facilitator Guide

This task redeploys Sepolia's game type 621 `AggregateVerifier` with updated proof program hashes
and registers it in the `DisputeGameFactory`. The three hashes are constructor immutables, so they
cannot be changed on the existing verifier.

Replace `<network>` with the rollout network, `sepolia`. Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory
(`active/evm/tasks/2026-09-21-update-cobalt-verifier-hashes/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This installs the `base/contracts` commit and dependencies used by the Cobalt deployment. The new
`AggregateVerifier` is compiled with the same 999999 optimizer runs and bytecode settings as the
verifier deployed by the original Cobalt task.

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `GAME_TYPE` is 621 and resolves to the expected current `AggregateVerifier`.
- `TEE_IMAGE_HASH` is the PCR0 of the intended Nitro enclave image.
- `ZK_RANGE_HASH` is the intended SP1 range verification key.
- `ZK_AGGREGATE_HASH` is the intended SP1 aggregation verification key.

Sepolia's current verifier is `0xC1a5aCb64e439A04017A526e3D8E5d3e79846448`. The configured changes
are the same hashes already registered on Zeronet:

| Hash | Current verifier | New verifier |
| --- | --- | --- |
| TEE image | `0xe8dc2300cf325b2527cbfa5e664a70acc40a9f2fc0617bd35cdfa61652a5fc30` | `0xb3d3746cf4b830046e9196dc196244d69fd96d3d436bd45ab84e35a9236f351f` |
| ZK range | `0x7713943c2c2412314b135c5606cdb3923a54f7555d91d9f31c2f64e34e16f2f4` | `0x776848834e7efcb029c48cf7215175b77098e8db28f27d2b074a64106f1c2b16` |
| ZK aggregation | `0x002663a1072dc1e1938e13d3b269fff88e843eb4ef76d6c6953dde4f5152973b` | `0x002663a1072dc1e1938e13d3b269fff88e843eb4ef76d6c6953dde4f5152973b` |

The aggregation key intentionally stays unchanged. The deploy script refuses to run if any new
hash is zero or all three hashes match the current verifier. Confirm and record the exact
`base/base` release or commit used to produce the TEE measurement and ZK keys before deployment.

## 3. Deploy and verify

```bash
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify
```

The shared deploy script reads every unchanged constructor value from the currently registered verifier:

- game type, anchor state registry, delayed WETH, TEE verifier, and ZK verifier;
- config hash, L2 chain ID, block intervals;
- `ProtocolVersions` registry; and
- L2 genesis block, genesis timestamp, and block time.

Only the three configured proof program hashes are supplied independently. The script checks every
copied immutable after deployment and writes the new verifier address and encoded constructor
arguments to `config/<network>/addresses.json`.

Commit `config/<network>/addresses.json` and the task-scoped `records/` broadcast artifacts.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`.
For Sepolia, remove the generated `taskOriginConfig` and add
`"skipTaskOriginValidation": true` at the JSON root before committing the files.

## 5. Collect signatures and execute

The `DisputeGameFactory` owner is Sepolia's 2-of-2 ProxyAdmin owner Safe. The Coinbase multisig
and Security Council each approve their nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

`execute` re-runs the pre- and postconditions and reverts instead of registering an unexpected
verifier.

## What the transaction does

One call from the `DisputeGameFactory` owner Safe:

```text
DisputeGameFactory.setImplementation(621, newAggregateVerifier)
```

This changes the implementation used when creating new game type 621 games. Existing games remain
bound to the implementation with which they were created. The task also asserts that the game
count and game constructor arguments do not change.

## Worth re-checking before signing

- **The version string remains `0.2.0`.** Confirm the new verifier by its address and the three hash
  getters rather than by `version()` alone.
- **Only the proof program hashes should change.** All other constructor immutables are copied from
  the live verifier and checked after deployment and registration.
- **The old verifier remains deployed.** The factory mapping changes for new games; this task does
  not alter or migrate existing games.
