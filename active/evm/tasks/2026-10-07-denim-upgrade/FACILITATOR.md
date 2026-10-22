# Denim upgrade facilitator guide

Sepolia executed `ExecuteDenimUpgradeWithL2Predeploys`: two Denim L1 calls and five L2 deposits.
Mainnet selects `ExecuteDenimUpgradeWithAllL2Predeploys`: two Denim L1 calls and thirteen L2 deposits,
fifteen calls in ONE ProxyAdmin-owner transaction. The Security Council approves this transaction once,
with eight member signatures. Zeronet ran `ExecuteDenimUpgrade` for Denim only. Leave the executed
paths and their network configurations unchanged.

| Change | Contracts touched |
| --- | --- |
| Fork-gated proof intervals for 200ms blocks | `AggregateVerifier` (redeployed as `0.3.0`), `DisputeGameFactory` (`setImplementation`) |
| Denim activation and minimum node version | `ProtocolVersions` (`registerUpgrade`, upgrade id 13) |
| First five L2 predeploy upgrades through `OptimismPortal` deposits | `L2ToL1MessagePasser` `1.2.0`, `L1Block` `1.8.0`, `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault` `1.6.0` |

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

For mainnet, verify the PCR0 and both SP1 verification keys against the v1.5.1 build provenance
in the network config before deploying or generating validations. The Sepolia f3a459f build cannot
derive post-Denim mainnet blocks because it disables mainnet Denim. Do not reuse its hashes.
Mainnet validation, approval and execution refuse missing hashes.

Build enclave and zk images from exactly base/base v1.5.1 at 5476069f1eb74a56bccb56fdefd4b4bb0e3cda42.
Use the proof-build recipes at 228352e514233177a65cc2d9873f6bf4b08e67cd, Rust 1.94.0 alpine,
linuxkit v1.8.2 and aws-nitro-enclaves-image-format 483114f. A different source revision, recipe or
toolchain can change the accepted hashes.

The mainnet script checks L1 chain id 1, L2 chain id 8453, the owner Safe's 2-of-2 membership,
Base 3-of-6 and Security Council 8-of-11, the current verifier's 600/30 intervals, portal version
6.0.1, the portal resource and L1 gas budgets described below, schedule length 13, canceled entry 7, last entry 1790791200,
and MIN_NOTICE 3600. It also checks the live L2 versions, proxy admins, legacy storage guards
and counterpart/vault configuration. Re-run `simulate-current` if any precondition changes.

Mainnet preserves the live vault recipients and L2 withdrawal networks. `BaseTime` is excluded:
Denim installs it only while its implementation slot is empty. The mainnet script refuses an occupied
implementation slot or an admin other than the L2 ProxyAdmin in both setup and the L2 post-check.

EAS mainnet `1.0.1` uses EIP-712 domain version `1.0.1`, not Sepolia's `1.2.0`. The new domain is
`1.3.0`. Outstanding delegated attestation/revocation signatures become invalid; clients must sign
again using the new domain, type hashes and delegation ABI. Existing attestations, schemas and nonces
remain at their existing storage locations.

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

For mainnet, then deploy the other eight implementations and LegacyMigrator with the task-local
Foundry project:

```bash
make TASK_NETWORK=<network> deploy-remaining-l2
make TASK_NETWORK=<network> simulate
```

The extra deployments use 0.8.15 for factories and bridges, 0.8.19 for attestations, and 0.8.25 for
OperatorFeeVault. Per-file factory optimizer profiles use 5000 runs; the other implementations use
999999 runs, no bytecode hash, and Cancun. The multisig script also builds from `active/evm` using
its default compiler settings. `simulate` (an alias for `test`) runs deterministic historical fork
tests with test-only verifier hashes and local implementations. It is not the current-state execution
prerequisite. The gas tests use `forge test --isolate`, so each measured ProxyAdmin call and
the owner-Safe execution starts a separate transaction with cold storage. Other tests run without
isolation so cheatcode basefee overrides remain effective. Neither simulation command deploys,
generates validations, signs or broadcasts.

The facilitator runs all deployment steps with a Ledger. `deploy-l2` uses the L2 RPC, 999999 optimizer runs,
no bytecode hash and Cancun, matching base/contracts. It appends `l2ToL1MessagePasser`, `l1Block`,
`sequencerFeeVault`, `baseFeeVault` and `l1FeeVault` to `config/<network>/addresses.json`. There is no
L2 source-verification step. Deploy the verifier first because its script replaces the address file;
`deploy` refuses to overwrite recorded L2 addresses. The fee-vault deployment uses Solidity 0.8.25,
while the verifier and other L2 deployment use 0.8.15.

Commit `config/<network>/addresses.json` and the task-scoped `records/` broadcast artifacts, then
fill in the implementation addresses in `config/<network>/README.md`. The combined validation,
approval and execution targets refuse to proceed until all six addresses on Sepolia, or all fifteen addresses on mainnet including the migrator, are present.

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
- Sepolia combined path: five separate `OptimismPortal.depositTransaction` calls to the L2 ProxyAdmin,
  with five `TransactionDeposited` events and portal resource-metering state changes such as resource
  params. Each deposit has zero value and a 200000 L2 gas limit. Check that the sender is the owner Safe.
- Mainnet: thirteen separate zero-value owner-Safe deposits to the L2 ProxyAdmin, each with a
  300000 gas limit, totaling 3900000 L2 gas against the portal's 20000000 resource limit. The first
  five calls are the Sepolia set above. The remaining eight are:

  | Target | New version | Method |
  | --- | --- | --- |
  | OptimismMintableERC721Factory | 1.4.2 | upgrade |
  | OperatorFeeVault | 1.1.0 | upgradeAndCall initialize |
  | SchemaRegistry | 1.3.1-beta.2 | upgrade |
  | EAS | 1.4.1-beta.3 | upgrade |
  | L2CrossDomainMessenger | 2.2.0 | upgradeAndCall LegacyMigrator.migrate |
  | L2StandardBridge | 1.13.0 | upgradeAndCall LegacyMigrator.migrate |
  | OptimismMintableERC20Factory | 1.10.2 | upgradeAndCall LegacyMigrator.migrate |
  | L2ERC721Bridge | 1.10.0 | upgradeAndCall LegacyMigrator.migrate |

  The four migrations clear legacy slot 0, install the final implementation, and initialize its
  counterpart atomically. On mainnet those slots contain only initializer flags or zero spacers,
  unlike Sepolia's packed state. All three fee vaults and OperatorFeeVault initialize their storage
  configuration without clearing totalProcessed in slot 0. The new ERC20 factory deployments mapping
  starts empty; it does not backfill tokens created by the old factory.
- L2 storage changes are not part of the L1 validation state diff. On mainnet, the script post-check validates the
  captured deposit arguments in order, including the target, zero value, gas limit, creation flag and
  calldata. It replays that decoded calldata on an L2 fork and checks implementation addresses,
  versions and all three vaults' initialized recipient, minimum withdrawal and withdrawal network.
  Sepolia replays its five expected calls and checks the same vault settings. Each upgrade is its own deposit so the
  L2 ProxyAdmin sees the aliased owner.
- Safe nonce and approval changes.

For mainnet, KEEP `taskOriginConfig`. Task-origin validation is required for this owner-Safe transaction.
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
```

On mainnet, first run `make TASK_NETWORK=mainnet simulate-current` after both approvals are onchain.
The current-state simulation requirements and gas budget are below.

```bash
make TASK_NETWORK=<network> execute
```

Execute at least one hour before `PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP`, preferably with
margin. `ProtocolVersions` enforces this one-hour `MIN_NOTICE`. Once registered, the activation can
only be delayed by the incident responder and freezes one hour before it lands.

The deposits execute on L2 shortly after the L1 transaction, not at Denim activation. The predeploy
upgrades have no ordering dependency on Denim. Check that all five Sepolia deposits, or all thirteen mainnet deposits, succeeded on L2.

Immediately after execution, roll the network's proposer and provers to the prover build documented in `config/<network>/.env`.
On mainnet this MUST be the reproducible v1.5.1-based build. Execute first, then roll immediately; do not roll before execution.
The new verifier accepts proofs only from that build, so proposals pause until the rollout lands; keep the gap short.
New enclave signers register themselves in `TEEProverRegistry` on startup. The nitro host's health check requires a signer valid
for the registry's current expected image hash, so the new build cannot be deployed before execution. Confirm the new signers
with the commands below (`TEE_PROVER_REGISTRY_PROXY` and `L1_RPC_URL` come from the repository's `config/<network>.env`),
checking each new signer's image hash equals `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`.

```bash
cast call "$TEE_PROVER_REGISTRY_PROXY" 'getRegisteredSigners()(address[])' --rpc-url "$L1_RPC_URL"
cast call "$TEE_PROVER_REGISTRY_PROXY" 'signerImageHash(address)(bytes32)' <signer> --rpc-url "$L1_RPC_URL"
```

After execution the script checks that the factory points at the new verifier, that Denim is upgrade
id 13 with the expected timestamp, that earlier upgrades are unchanged, and that the new verifier
returns the slow intervals for the block before Denim and the fast intervals from the first Denim
block. On the combined path it also checks the five Sepolia or thirteen mainnet successful owner-Safe deposits, replays each
on an L2 fork as the aliased owner, and checks implementations, versions, fee-vault config and the
unchanged L2 ProxyAdmin owner. Set the README status to the execution transaction link.

Immediately before mainnet execution, after both Safe approvals are onchain, run from this directory:

```bash
make TASK_NETWORK=mainnet simulate-current
```

This invokes `MultisigScript.simulate(bytes)` with `0x` signatures, the real implementations from
`config/mainnet/addresses.json`, and the current L1 and L2 RPC heads. It checks the prerequisites,
including the notice window, simulates the owner transaction using the actual approvals, and replays
all deposits on the current L2 fork. Missing deployment addresses or approvals stop the command.
Do not execute unless it succeeds; the historical `test` / `simulate` target is not a substitute.

The historical isolated gas tests require 1.5 times each deposit's total gas to fit within 300000.
The total includes execution gas, 21000 intrinsic gas and calldata gas. They include CALL and measurement overhead
in execution gas and take no refund credit. The largest measured total is 126660 gas for each of
the standard bridge and ERC721 bridge migrations, requiring 189990 gas with the margin. A plain
upgrade measures 24506 execution gas, not the warm 6933. The 300000 uniform limit remains unchanged.
These are historical fixture measurements; `simulate-current` checks the actual deposited calldata
and replays it with the deposit gas limit minus intrinsic and calldata gas, but does not measure
cold transaction gas.
Portal burn for all deposits
is bounded by `3900000 * fee / max(L1 basefee, 1 gwei)` without credit for metered work.
In `setUp` (validation, approval and execution simulations), the script reads live portal `params()`
and resource configuration. It bounds `fee` by `prevBaseFee` plus any positive first-deposit fee
update from the previous block's bought gas, applies the configured minimum (and maximum on a block
update), and takes no
credit for empty-block decay. It requires this burn plus a 5000000 base-cost allowance to be at most
14000000 gas. The isolated owner transaction measures 4218345 gas including intrinsic and calldata
gas, without refund credit. The test requires at least 10% margin within the 5000000 allowance.
The allowance rounds that baseline up by ~18.5%,
then adds the full metering burn without subtracting the baseline's burn. The 14000000 ceiling
leaves 2777216 gas (~16.6%) below the EIP-7825 per-transaction cap of 16777216. At a 1 gwei portal
fee and L1 basefee below 1 gwei the burn bound is 3900000; each additional 1 gwei adds 3900000.

Fees and resource use can change after simulation. Recheck immediately before submission and do
not override a failed guard or split this transaction. The L1 block limit and portal resource limit
do not protect against the per-transaction cap.
