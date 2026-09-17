# Cobalt Upgrade — Facilitator Guide

This task delivers the three Cobalt L1 changes in a single ProxyAdmin-owner transaction.
On Sepolia it also folds in the hinted Nitro TEE registry cutover as a sixth call:

| Change | Contracts touched |
| --- | --- |
| Dynamic upgrades | `ProtocolVersions` (new proxy + implementation), `AggregateVerifier` (redeployed to bind it) |
| EthLockbox removal | `OptimismPortal2`, `SystemConfig` |
| CREATE2 for dispute games | `DisputeGameFactory` |
| Hinted Nitro TEE cutover (Sepolia) | `TEEProverRegistry` proxy, plus EOA-deployed `P384Verifier` / `CertManager` / `NitroValidator` |

Replace `<network>` with the network you are rolling out, for example `zeronet`. Every command
requires `TASK_NETWORK` explicitly — there is no default. Run everything from this directory
(`active/evm/tasks/2026-09-14-cobalt-upgrade/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT`, installs the extra OpenZeppelin, solmate,
and `nitro-validator` dependencies that building those sources requires, and applies
`patch/max-gas-limit.patch`.

The patch matters. Zeronet runs a `SystemConfig` that raises `MAX_GAS_LIMIT` to 2,000,000,000, and
Cobalt modifies `SystemConfig`. Deploying a stock build would quietly drop the chain back to
500,000,000. The patch re-applies the raise and tags the semver `3.14.0+max-gas-limit-2000M`, and
the deploy script refuses to proceed if that version string is missing. On a network that does not
run the patched build, drop `apply-patches` from the `deps` prerequisites and relax the version
assertions in `DeployCobaltCoreImpls` and `ExecuteCobaltUpgrade` to the stock `3.14.0`.

## 2. Review the network config

Open `config/<network>/.env` and confirm every value, in particular:

- `PROTOCOL_VERSIONS_INITIAL_SCHEDULE` — the activation timestamp imported for each upgrade id.
  Ids should stay aligned with the Base mainnet registry so that a given index means the same fork
  on every chain. Entries may be `0` for an unscheduled fork. Every entry except Cobalt's is a fork
  that has already happened, so each one must match the network's chain config in
  [base/base](https://github.com/base/base/blob/main/crates/common/chains/src/config.rs), which is
  what the nodes actually fork on. Do not assume a re-genesised network has everything active at the
  genesis timestamp: on Zeronet, Azul and Beryl activated a few minutes after genesis, and id 7
  (PectraBlobSchedule) is unscheduled at `0`. Cobalt (id 12) is the activation this task schedules,
  and the node config carries no Cobalt timestamp until its own rollout lands.
- `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` — must be non-zero and fit in 128 bits. The comment
  above it gives the `cast` command to re-derive the packed value from the human-readable version.
- `PROTOCOL_VERSIONS_INCIDENT_RESPONDER` — the address allowed to use the incident path.
- `OLD_*` — the currently deployed implementations. `ExecuteCobaltUpgrade` asserts these match the
  live proxies before building any calls, so a stale value stops the task rather than upgrading
  from an unexpected base.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` — all three rotate for Cobalt. The TEE value is PCR0 of
  the Nitro enclave; the ZK values are the SP1 keys from `just succinct vkeys --build`. Zeronet and
  Sepolia use the same values from
  [`releases/v1.4.0`](https://github.com/base/base/tree/releases/v1.4.0). The deploy script refuses a
  zero hash or a hash that still matches the live verifier. Every other `AggregateVerifier`
  constructor argument is read back from the live implementation at deploy time.
- Sepolia TEE anchors — `OLD_TEE_PROVER_REGISTRY_IMPL`, `OLD_NITRO_VERIFIER`,
  `CERT_MANAGER_OWNER`, and `CERT_MANAGER_REVOKER`. Re-check the live registry implementation
  and `NITRO_VERIFIER()` before deploying. `ExecuteCobaltUpgrade` only emits the sixth call
  when `NEW_TEE_PROVER_REGISTRY_IMPL` is present in `addresses.json`.

## 3. Deploy

```bash
make TASK_NETWORK=<network> deploy
```

This runs two steps because `base/contracts` pins different optimizer settings per contract, and
reproducible bytecode requires honouring them:

1. `deploy-core` (5000 runs) — `OptimismPortal2`, `SystemConfig`, `DisputeGameFactory`
   implementations and the `ProtocolVersions` proxy.
2. `deploy-proofs` (999999 runs) — the `ProtocolVersions` implementation and `AggregateVerifier`.

The proxy is deployed in the first step because `AggregateVerifier` takes its address as a
constructor immutable. It is left pointing at no implementation; the upgrade transaction sets and
initializes it atomically. Each step writes to `config/<network>/addresses.json` and asserts its own
postconditions, so a wrong constructor argument fails at deploy time rather than at signing time.

Then verify the source:

```bash
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-core
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify-proofs
```

On Sepolia, also deploy the hinted Nitro stack. These targets are not part of `make deploy`,
so a Zeronet re-run cannot accidentally redeploy them:

```bash
make TASK_NETWORK=sepolia deploy-nitro-validator
VERIFIER_API_KEY=<key> make TASK_NETWORK=sepolia verify-nitro-validator
make TASK_NETWORK=sepolia deploy-tee-registry-impl
VERIFIER_API_KEY=<key> make TASK_NETWORK=sepolia verify-tee-registry-impl
```

This writes `p384Verifier`, `certManager`, `nitroValidator`, and `teeProverRegistryImpl` into
`config/sepolia/addresses.json` without overwriting the Cobalt addresses.

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts.

Before generating Sepolia validations, register the new-PCR0 Cobalt enclaves on the live `0.5.0`
registry. Call 5 rotates `TEE_IMAGE_HASH`, so only those signers stay valid after execute.
`signerImageHash` is storage and survives the implementation swap.

Then migrate the offchain registrar to signer `0x8074b32bD7d06C8f27596F3D6fbf867A36eA22a3` and keep
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
For Sepolia (and any non-mainnet rollout) remove each generated `taskOriginConfig` and add this
root field:

```json
"skipTaskOriginValidation": true
```

Commit them, then set the `config/<network>/README.md` status to `READY TO SIGN` and share it with
signers.

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

Five calls on Zeronet, six on Sepolia, all from the ProxyAdmin owner Safe:

1. `ProxyAdmin.upgradeAndCall(protocolVersionsProxy, protocolVersionsImpl, initialize(...))` —
   `initialize` is `reinitializer(1)` on a never-initialized proxy, so it must be bundled with the
   implementation set rather than sent separately.
2. `ProxyAdmin.upgrade(optimismPortal, newImpl)`
3. `ProxyAdmin.upgrade(systemConfig, newImpl)`
4. `ProxyAdmin.upgrade(disputeGameFactory, newImpl)`
5. `DisputeGameFactory.setImplementation(621, newAggregateVerifier)`
6. `ProxyAdmin.upgrade(teeProverRegistryProxy, newTeeProverRegistryImpl)` — Sepolia only, when
   `NEW_TEE_PROVER_REGISTRY_IMPL` is set. Storage (owners, signers, per-signer image hashes,
   proposers, game type) is unchanged; only the implementation and nitro wiring change. Call 5
   does rotate the expected TEE image hash, because the registry reads it from the new
   AggregateVerifier.

Calls 2–4 and 6 are bare upgrades: none of those implementations adds state or bumps its init
version, so there is nothing to reinitialize.

## Worth re-checking before signing

- **Every changed contract bumps its version.** `OptimismPortal2` goes `5.2.0` -> `6.0.0`,
  `DisputeGameFactory` `1.4.0` -> `1.5.0`, `AggregateVerifier` `0.1.0` -> `0.2.0`, and `SystemConfig`
  `3.13.2+max-gas-limit-2000M` -> `3.14.0+max-gas-limit-2000M`, so `version()` read through each
  proxy is a sound check that the upgrade landed. On Sepolia, `TEEProverRegistry` goes
  `0.5.0` -> `0.6.1` and `NITRO_VERIFIER` is replaced by `NITRO_VALIDATOR`.
- **The Cobalt activation is scheduled, so the transaction is time-sensitive.**
  `ProtocolVersions.initialize` enforces one hour of notice on future timestamps, so it reverts if
  the upgrade lands within the hour before the configured Cobalt activation. Execute well before
  that window, or push the timestamp out.
