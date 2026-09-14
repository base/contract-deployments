# Cobalt Upgrade — Facilitator Guide

This task delivers the three Cobalt L1 changes in a single ProxyAdmin-owner transaction:

| Cobalt change | Contracts touched |
| --- | --- |
| Dynamic upgrades | `ProtocolVersions` (new proxy + implementation), `AggregateVerifier` (redeployed to bind it) |
| EthLockbox removal | `OptimismPortal2`, `SystemConfig` |
| CREATE2 for dispute games | `DisputeGameFactory` |

Replace `<network>` with the network you are rolling out, for example `zeronet`. Every command
requires `TASK_NETWORK` explicitly — there is no default. Run everything from this directory
(`active/evm/tasks/2026-09-14-cobalt-upgrade/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT`, installs the extra OpenZeppelin and solmate
dependencies that building those sources requires, and applies `patch/max-gas-limit.patch`.

The patch matters. Zeronet runs a `SystemConfig` that raises `MAX_GAS_LIMIT` to 2,000,000,000, and
Cobalt modifies `SystemConfig`. Deploying a stock build would quietly drop the chain back to
500,000,000. The patch re-applies the raise and tags the semver `3.13.2+max-gas-limit-2000M`, and
the deploy script refuses to proceed if that version string is missing. On a network that does not
run the patched build, drop `apply-patches` from the `deps` prerequisites and relax the version
assertions in `DeployCobaltCoreImpls` and `ExecuteCobaltUpgrade` to the stock `3.13.2`.

## 2. Review the network config

Open `config/<network>/.env` and confirm every value, in particular:

- `PROTOCOL_VERSIONS_INITIAL_SCHEDULE` — the activation timestamp imported for each upgrade id.
  Ids should stay aligned with the Base mainnet registry so that a given index means the same fork
  on every chain. Entries may be `0` for an unscheduled fork. Zeronet was re-genesised with every
  fork through Beryl already active, so ids 0–11 carry the genesis timestamp and Cobalt (id 12)
  is `0`.
- `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` — must be non-zero and fit in 128 bits. The comment
  above it gives the `cast` command to re-derive the packed value from the human-readable version.
- `PROTOCOL_VERSIONS_INCIDENT_RESPONDER` — the address allowed to use the incident path.
- `OLD_*` — the currently deployed implementations. `ExecuteCobaltUpgrade` asserts these match the
  live proxies before building any calls, so a stale value stops the task rather than upgrading
  from an unexpected base.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` — the proof program hashes, derived from the Base node
  release these games prove against. They ship blank and the deploy script refuses to run until
  they are filled in. Every other `AggregateVerifier` constructor argument, including the config
  hash and the block intervals, is read back from the live implementation at deploy time, so the
  redeploy cannot change them.

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

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`.
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

Five calls, all from the ProxyAdmin owner Safe:

1. `ProxyAdmin.upgradeAndCall(protocolVersionsProxy, protocolVersionsImpl, initialize(...))` —
   `initialize` is `reinitializer(1)` on a never-initialized proxy, so it must be bundled with the
   implementation set rather than sent separately.
2. `ProxyAdmin.upgrade(optimismPortal, newImpl)`
3. `ProxyAdmin.upgrade(systemConfig, newImpl)`
4. `ProxyAdmin.upgrade(disputeGameFactory, newImpl)`
5. `DisputeGameFactory.setImplementation(621, newAggregateVerifier)`

Calls 2–4 are bare upgrades: none of those implementations adds state or bumps its init version, so
there is nothing to reinitialize.

## Worth re-checking before signing

- **Version strings cannot tell old from new.** `OptimismPortal2` stays at `5.2.0`,
  `DisputeGameFactory` at `1.4.0`, and `AggregateVerifier` at `0.1.0` across this change, so
  `version()` is not a useful check for any of them. Confirm the implementation addresses instead.
  For the verifier, the `PROTOCOL_VERSIONS()` getter is the real discriminator: the predecessor
  predates the registry and reverts on that call.
- **The Cobalt activation is scheduled, so the transaction is time-sensitive.**
  `ProtocolVersions.initialize` enforces one hour of notice on future timestamps, so it reverts if
  the upgrade lands within the hour before the configured Cobalt activation. Execute well before
  that window, or push the timestamp out.
