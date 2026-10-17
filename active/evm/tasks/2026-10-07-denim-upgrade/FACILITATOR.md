# Denim upgrade facilitator guide

Sepolia and mainnet use `ExecuteDenimUpgradeWithL2Predeploys` for the two Denim L1 calls and five
L2 upgrade deposits in one ProxyAdmin-owner transaction. The Security Council signs once.
Zeronet ran `ExecuteDenimUpgrade` for Denim only and upgraded the L2 predeploys separately.
The unset `UPGRADE_SCRIPT_NAME` preserves that Denim-only path. For the combined path, set
`UPGRADE_SCRIPT_NAME=ExecuteDenimUpgradeWithL2Predeploys` in `config/<network>/.env`.

| Change | Contracts touched |
| --- | --- |
| Fork-gated proof intervals for 200ms blocks | `AggregateVerifier` (redeployed as `0.3.0`), `DisputeGameFactory` (`setImplementation`) |
| Denim activation and minimum node version | `ProtocolVersions` (`registerUpgrade`, upgrade id 13) |
| L2 predeploy upgrades through `OptimismPortal` deposits | `L2ToL1MessagePasser` `1.2.0`, `L1Block` `1.8.0`, `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault` `1.6.0` |

`AggregateVerifier` `0.3.0` carries two proposal interval pairs: the slow pair for 2s blocks and the
fast pair for Denim's 200ms blocks. It reads the Denim activation from `ProtocolVersions` index 13 and
selects the pair from each game's starting block, so the cadence switch needs no action during the
fork. Until Denim activates it behaves like `0.2.0`.

Replace `<network>` with the rollout network (`zeronet`, `sepolia` or later `mainnet`). Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory (`active/evm/tasks/2026-10-07-denim-upgrade/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT` for the verifier and L2 implementations.

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `OLD_AGGREGATE_VERIFIER` is the verifier currently registered for game type 621 (version `0.2.0`).
- `FAST_BLOCK_INTERVAL` / `FAST_INTERMEDIATE_BLOCK_INTERVAL` are 6000 / 300. With the live slow pair
  (600 / 30) both yield 20 intermediate roots and a 20 minute range.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` come from the proof program build the network's provers run
  at Denim, as documented in `config/<network>/.env`. The deploy script refuses to run while any of
  them is blank.
- `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP` matches the Denim activation in the base/base release
  that activates Denim on the network.
- `PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION` is the live value and
  `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` is that release's version.
- For the combined path, confirm `FEE_VAULT_RECIPIENT`, `FEE_VAULT_MIN_WITHDRAWAL_AMOUNT` and
  `FEE_VAULT_WITHDRAWAL_NETWORK` against all three live L2 vaults. Sepolia preserves L2 withdrawals
  to its existing L2 recipient contract. Do not copy Zeronet's L1 withdrawal setting.
- RPCs, Safe addresses and `OPTIMISM_PORTAL` come from the repository's `config/<network>.env`.

Every other `AggregateVerifier` constructor argument is copied from the live verifier at deploy time.

## 3. Deploy and verify

```bash
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify
```

`deploy` builds with 999999 optimizer runs and no bytecode hash, matching base/contracts' settings
for `AggregateVerifier`. It checks every immutable of the new verifier and writes
`aggregateVerifier` and its constructor arguments to `config/<network>/addresses.json`.

For the combined path, deploy the five L2 implementations after deploying the verifier:

```bash
make TASK_NETWORK=<network> deploy-l2
```

Jack runs both deployment steps with a Ledger. `deploy-l2` uses the L2 RPC, 999999 optimizer runs,
no bytecode hash and Cancun, matching base/contracts. It appends `l2ToL1MessagePasser`, `l1Block`,
`sequencerFeeVault`, `baseFeeVault` and `l1FeeVault` to `config/<network>/addresses.json`. There is no
L2 source-verification step. Deploy the verifier first because its script replaces the address file;
`deploy` refuses to overwrite recorded L2 addresses. The fee-vault deployment uses Solidity 0.8.25,
while the verifier and other L2 deployment use 0.8.15.

Commit `config/<network>/addresses.json` and the task-scoped `records/` broadcast artifacts, then
fill in the implementation addresses in `config/<network>/README.md`. The combined validation,
approval and execution targets refuse to proceed until all six implementation addresses are present.

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
- Combined path only: five separate `OptimismPortal.depositTransaction` calls to the L2 ProxyAdmin,
  with five `TransactionDeposited` events and portal resource-metering state changes such as resource
  params. Each deposit has zero value and a 200000 L2 gas limit. Check that the sender is the owner Safe.
- L2 storage changes are not part of the L1 validation state diff. The script post-check replays the
  deposits on an L2 fork and checks implementation addresses, versions and all three vaults' initialized
  recipient, minimum withdrawal and withdrawal network. Each upgrade is its own deposit so the
  L2 ProxyAdmin sees the aliased owner.
- Safe nonce and approval changes.

For any non-mainnet rollout, remove each generated `taskOriginConfig` and add this root field:

```json
"skipTaskOriginValidation": true
```

Commit them and share `config/<network>/README.md` with signers.

## 5. Collect signatures and execute

The ProxyAdmin owner is a 2-of-2 of the Base multisig and the Security Council, so each approves its
own nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

Execute at least one hour before `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP`, preferably with
margin. `ProtocolVersions` enforces this one-hour `MIN_NOTICE`. Once registered, the activation can
only be delayed by the incident responder and freezes one hour before it lands.

The deposits execute on L2 shortly after the L1 transaction, not at Denim activation. The predeploy
upgrades have no ordering dependency on Denim. Check that all five deposits succeeded on L2.

After execution the script checks that the factory points at the new verifier, that Denim is upgrade
id 13 with the expected timestamp, that earlier upgrades are unchanged, and that the new verifier
returns the slow intervals for the block before Denim and the fast intervals from the first Denim
block. On the combined path it also checks the five successful owner-Safe deposits, replays each
on an L2 fork as the aliased owner, and checks implementations, versions, fee-vault config and the
unchanged L2 ProxyAdmin owner. Set the README status to the execution transaction link.
