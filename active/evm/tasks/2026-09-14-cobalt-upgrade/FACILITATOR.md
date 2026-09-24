# Cobalt Upgrade — Facilitator Guide

This task delivers the Cobalt L1 changes in a single ProxyAdmin-owner transaction. Sepolia and
mainnet also fold in the hinted Nitro TEE registry cutover.

| Change | Contracts touched |
| --- | --- |
| Dynamic upgrades | `ProtocolVersions`, `AggregateVerifier` (redeployed to bind it) |
| EthLockbox removal | `OptimismPortal2`, `SystemConfig` |
| CREATE2 for dispute games | `DisputeGameFactory` |
| Hinted Nitro TEE cutover | `TEEProverRegistry` proxy, plus EOA-deployed `P384Verifier` / `CertManager` / `NitroValidator` |

Replace `<network>` with the network you are rolling out, for example `zeronet`. Every command
requires `TASK_NETWORK` explicitly — there is no default. Run everything from this directory
(`active/evm/tasks/2026-09-14-cobalt-upgrade/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT`, installs the extra OpenZeppelin, solmate,
and `nitro-validator` dependencies that building those sources requires. Networks with
`APPLY_MAX_GAS_LIMIT_PATCH=false` use the stock `SystemConfig`; the others apply
`patch/max-gas-limit.patch`.

The patch matters. Zeronet runs a `SystemConfig` that raises `MAX_GAS_LIMIT` to 2,000,000,000, and
Cobalt modifies `SystemConfig`. Deploying a stock build would quietly drop the chain back to
500,000,000. The patch re-applies the raise and tags the semver `3.14.0+max-gas-limit-2000M`, and
the deploy script refuses to proceed if that version string is missing. On a network that does not
run the patched build, set `APPLY_MAX_GAS_LIMIT_PATCH=false` and
`EXPECTED_SYSTEM_CONFIG_VERSION=3.14.0`.

## 2. Review the network config

Open `config/<network>/.env` and confirm every value, in particular:

- For networks initializing `ProtocolVersions` in this task, `PROTOCOL_VERSIONS_INITIAL_SCHEDULE`
  is the activation timestamp imported for each upgrade id.
  Ids should stay aligned with the Base mainnet registry so that a given index means the same fork
  on every chain. Entries may be `0` for an unscheduled fork. Every entry except Cobalt's is a fork
  that has already happened, so each one must match the network's chain config in
  [base/base](https://github.com/base/base/blob/main/crates/common/chains/src/config.rs), which is
  what the nodes actually fork on. Do not assume a re-genesised network has everything active at the
  genesis timestamp: on Zeronet, Azul and Beryl activated a few minutes after genesis, and id 7
  (PectraBlobSchedule) is unscheduled at `0`. Cobalt (id 12) is the activation this task schedules,
  and the node config carries no Cobalt timestamp until its own rollout lands.
- For those same networks, `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` must be non-zero and fit in
  128 bits, and `PROTOCOL_VERSIONS_INCIDENT_RESPONDER` is the incident path address.
- `PROTOCOL_VERSIONS_DEPLOYMENT_JSON` — when set, the task reuses the proxy and implementation from
  the standalone deployment instead of deploying or initializing another registry. Mainnet uses
  this path, verifies that the registry's schedule commitment remains unchanged, and raises its
  minimum protocol version from `PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION` to
  `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION`.
- `OLD_*` — the currently deployed implementations. `ExecuteCobaltUpgrade` asserts these match the
  live proxies before building any calls, so a stale value stops the task rather than upgrading
  from an unexpected base.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` — all three rotate for Cobalt. The TEE value is PCR0 of
  the Nitro enclave; the ZK values are the SP1 keys from `just succinct vkeys --build`. Zeronet and
  Sepolia use the same values from
  the network's finalized node release. Mainnet's values come from the finalized
  `releases/v1.4.2` enclave and vkey builds and remain blank until those exact outputs are recorded.
  The deploy script refuses a zero hash or a hash that still matches the live verifier. Every other
  `AggregateVerifier` constructor argument is read back from the live implementation at deploy time.
- TEE anchors — `OLD_TEE_PROVER_REGISTRY_IMPL`, `OLD_NITRO_VERIFIER`,
  `CERT_MANAGER_OWNER`, and `CERT_MANAGER_REVOKER`. Re-check the live registry implementation
  and `NITRO_VERIFIER()` before deploying. `ExecuteCobaltUpgrade` only emits the TEE upgrade call
  when `NEW_TEE_PROVER_REGISTRY_IMPL` is present in `addresses.json`.

## 3. Deploy

```bash
make TASK_NETWORK=<network> deploy
```

This runs two steps because `base/contracts` pins different optimizer settings per contract, and
reproducible bytecode requires honouring them:

1. `deploy-core` (5000 runs) — `OptimismPortal2`, `SystemConfig`, `DisputeGameFactory`
   implementations and, unless predeployed, the `ProtocolVersions` proxy.
2. `deploy-proofs` (999999 runs) — `AggregateVerifier` and, unless predeployed, the
   `ProtocolVersions` implementation.

Each step writes to `config/<network>/addresses.json` and asserts its own postconditions. Mainnet
must complete `2026-09-21-deploy-protocol-versions` first; these steps copy that task's deployed
addresses and bind the new `AggregateVerifier` to the initialized registry.

Then verify the source:

```bash
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-core
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-proofs
```

Mainnet sets `DEPLOY_TEE_WITH_COBALT=true`, so its `make deploy` runs the Nitro and TEE deployments
after `deploy-core` and `deploy-proofs`. Other networks can run the same steps separately:

```bash
make TASK_NETWORK=<network> deploy-nitro-validator
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-nitro-validator
make TASK_NETWORK=<network> deploy-tee-registry-impl
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-tee-registry-impl
```

This writes `p384Verifier`, `certManager`, `nitroValidator`, and `teeProverRegistryImpl` into
`config/<network>/addresses.json` without overwriting the Cobalt addresses.

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts.

Before generating validations for a TEE cutover, register the new-PCR0 Cobalt enclaves on the live
`0.5.0` registry. Registering the new AggregateVerifier rotates `TEE_IMAGE_HASH`, so only those
signers stay valid after execute.
`signerImageHash` is storage and survives the implementation swap.

Then migrate the offchain registrar to the network's configured `CERT_MANAGER_REVOKER` and keep
`BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` so AWS CRL checks still work. Stop the old registrar
immediately before `execute`. There is no standalone TEE rollback in this task: a failed cutover
means rolling the whole Cobalt bundle back. After execute, start the migrated registrar and rotate
one enclave first.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`.
For any non-mainnet rollout, remove each generated `taskOriginConfig` and add this root field:

```json
"skipTaskOriginValidation": true
```

Commit them, then set the `config/<network>/README.md` status to `READY TO SIGN` and share it with
signers.

For mainnet, generate and commit the task-origin signatures after the validations are final:

```bash
make TASK_NETWORK=mainnet sign-as-task-creator
make TASK_NETWORK=mainnet sign-as-base-facilitator
make TASK_NETWORK=mainnet sign-as-sc-facilitator
```

## 5. Collect signatures and execute

The ProxyAdmin owner is a 2-of-2 of the Base multisig and the Security Council, so each approves
its own nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

`execute` re-runs the same pre- and postconditions inside the broadcast, so it will revert rather
than land a partial upgrade.

## What the upgrade transaction does

Five calls on Zeronet, six on Sepolia and mainnet, all from the ProxyAdmin owner Safe:

1. Networks without a predeployed registry use
   `ProxyAdmin.upgradeAndCall(protocolVersionsProxy, protocolVersionsImpl, initialize(...))`.
   Mainnet instead calls `ProtocolVersions.setMinimumProtocolVersion` to move from v1.4.1 to v1.4.2.
2. `ProxyAdmin.upgrade(optimismPortal, newImpl)`
3. `ProxyAdmin.upgrade(systemConfig, newImpl)`
4. `ProxyAdmin.upgrade(disputeGameFactory, newImpl)`
5. `DisputeGameFactory.setImplementation(621, newAggregateVerifier)`
6. `ProxyAdmin.upgrade(teeProverRegistryProxy, newTeeProverRegistryImpl)` — when
   `NEW_TEE_PROVER_REGISTRY_IMPL` is set. Storage (owners, signers, per-signer image hashes,
   proposers, game type) is unchanged; only the implementation and nitro wiring change. Registering
   the AggregateVerifier rotates the expected TEE image hash, because the registry reads it from the
   new AggregateVerifier.

Calls 2–4 and 6 are bare upgrades: none of those implementations adds state or bumps its init
version, so there is nothing to reinitialize.

## Worth re-checking before signing

- **Every changed contract bumps its version.** `OptimismPortal2` goes `5.2.0` -> `6.0.0`,
  `DisputeGameFactory` `1.4.0` -> `1.5.0`, `AggregateVerifier` `0.1.0` -> `0.2.0`, and `SystemConfig`
  moves to the configured `EXPECTED_SYSTEM_CONFIG_VERSION`, so `version()` read through each proxy
  is a sound check that the upgrade landed. On TEE cutovers, `TEEProverRegistry` goes
  `0.5.0` -> `0.6.1` and `NITRO_VERIFIER` is replaced by `NITRO_VALIDATOR`.
- **A scheduled Cobalt activation is time-sensitive.** Networks that initialize the registry in
  this transaction must execute before the one-hour notice window. Mainnet's standalone registry
  task already scheduled Cobalt for September 30, 2026 at 18:00 UTC; this transaction leaves that
  schedule unchanged.
