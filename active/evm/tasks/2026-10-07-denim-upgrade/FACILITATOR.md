# Denim Upgrade — Facilitator Guide

This task delivers the Denim L1 changes in a single ProxyAdmin-owner transaction.

| Change | Contracts touched |
| --- | --- |
| Fork-gated proof intervals for 200ms blocks | `AggregateVerifier` (redeployed as `0.3.0`), `DisputeGameFactory` (`setImplementation`) |
| Denim activation and minimum node version | `ProtocolVersions` (`registerUpgrade`, upgrade id 13) |

`AggregateVerifier` `0.3.0` carries two proposal interval pairs: the slow pair for 2s blocks and the
fast pair for Denim's 200ms blocks. It reads the Denim activation from `ProtocolVersions` index 13 and
selects the pair from each game's starting block, so the cadence switch needs no action during the
fork. Until Denim activates it behaves like `0.2.0`.

Replace `<network>` with the rollout network (`zeronet`). Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory (`active/evm/tasks/2026-10-07-denim-upgrade/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT` and installs the OpenZeppelin and solmate
versions from base/contracts' justfile. `AggregateVerifier` is the only contract that differs from
the live `releases/v8.3.0` source.

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `OLD_AGGREGATE_VERIFIER` is the verifier currently registered for game type 621 (version `0.2.0`).
- `FAST_BLOCK_INTERVAL` / `FAST_INTERMEDIATE_BLOCK_INTERVAL` are 6000 / 300. With the live slow pair
  (600 / 30) both yield 20 intermediate roots and a 20 minute range.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` come from the base/base release that activates Denim. The
  deploy script refuses to run while any of them is blank.
- `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP` matches the Denim activation in that release.
- `PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION` is the live value and
  `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` is that release's version.

Every other `AggregateVerifier` constructor argument is copied from the live verifier at deploy time.

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

- `DisputeGameFactory`: `gameImpls[621]` moves from `OLD_AGGREGATE_VERIFIER` to the new verifier.
- `ProtocolVersions`: a 14th schedule entry (Denim) with
  `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP`, the extended schedule id chain, and the new
  minimum protocol version.
- Safe nonce and approval changes.

Commit them and share `config/<network>/README.md` with signers.

## 5. Collect signatures and execute

The ProxyAdmin owner is a 2-of-2 of the Base multisig and the Security Council, so each approves its
own nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

`ProtocolVersions` rejects a new activation less than one hour (`MIN_NOTICE`) away, so execute well
before `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP`. Once registered, the activation can only be
delayed (by the incident responder) and freezes one hour before it lands.

After execution the script checks that the factory points at the new verifier, that Denim is upgrade
id 13 with the expected timestamp, that earlier upgrades are unchanged, and that the new verifier
returns the slow intervals for the block before Denim and the fast intervals from the first Denim
block. Set the README status to the execution transaction link.
