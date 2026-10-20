# Remaining L2 predeploy upgrades

This task upgrades eight predeploys through eight separate L1 deposits to the L2 ProxyAdmin. The L1 ProxyAdmin owner's L2 alias must own the L2 ProxyAdmin. The script supports only Sepolia L1 and Base Sepolia L2. Every Make command requires command-line `TASK_NETWORK`.

The messenger, standard bridge, ERC20 factory and ERC721 bridge need a storage migration because their live initializer version is 2 and v8.4.0 exposes version-1 initializers. Each deposit calls `ProxyAdmin.upgradeAndCall(proxy, migrator, migrate(newImpl, initData))`. The task-local migrator runs in the proxy's context, clears only slot 0, writes the final EIP-1967 implementation and emits `Upgraded`. It delegatecalls the new implementation's `initialize(address)` and bubbles any revert. A failed L2 call reverts the whole upgradeAndCall, including both implementation changes and all storage writes, leaving the old implementation and storage intact. No proxy remains on the migrator between deposits. Direct calls to the migrator revert. Its own writes never touch the admin slot.

Slot 0 contains initializer flags at byte offset 20 on the messenger and offset 0 on the other three. Clearing it discards only flags, zero spacers, the ERC20 factory's legacy packed bridge and the ERC721 bridge's legacy packed messenger. The new layouts treat those packed address bytes as unused spacers. Initializers restore the live configuration in the new slots: messenger counterpart at 207; standard bridge messenger at 3 and counterpart at 4; ERC20 factory bridge at 1; ERC721 bridge messenger at 1 and counterpart at 2. All four constructors disable initializers on the implementation itself. The messenger initializer preserves a non-zero xDomainMsgSender at slot 204 and does not touch the nonce or message mappings. The bridges only write their messenger and counterpart; the factory only writes its bridge, apart from initializer flags.

BaseTime stays excluded because Denim must install its canonical implementation while its proxy implementation slot is zero. Ordering is independent of Denim activation. None of the eight implementations or their initialization paths reads BaseTime or the new L1Block fields, and Denim's network transition does not upgrade these eight proxies. Messenger gas estimation includes a calldata floor but does not require activation or a new predeploy. There is no timestamp guard. EAS changes its delegated-signature domain version to 1.3.0, invalidating outstanding signatures for 1.2.0.

Run from this task directory. Replace `<network>` with the configured network. The invocation currently accepts only `sepolia`.

## Prepare and simulate

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> build
make TASK_NETWORK=<network> simulate-l2
```

Review `config/<network>/.env` against fresh live reads. The shared fork replay rejects changed legacy slot-0 values, counterparts, factory configuration, vault configuration or owner, an initialized operator vault, and a messenger whose sender is not the idle default. It checks all implementations, versions, initializer flags and configuration after replay, and preserves the messenger nonce, idle sender and vault totalProcessed. Tests also preserve message, deposit, schema, attestation and factory records; create an ERC20 token and exercise bridge mint/burn; and prove failed migrations roll back on all four proxies. The L1 test exercises MultisigScript's signer simulation and the same L2 post-check with local implementations persisted across forks. No test broadcasts.

The internal L1 RPC may be unavailable. Select a public Sepolia RPC explicitly with `L1_RPC_URL=<url>` on any command. `config/<network>/.env` selects the public L2 RPC.

## Deploy implementations

```bash
make TASK_NETWORK=<network> deploy
```

Only the facilitator runs this step with an L2-funded deployment account. The task-local Foundry config matches base/contracts at the pinned release: Solidity 0.8.15 with 5000 optimizer runs for both factories and the ERC721 token, and 999999 for the messenger, bridges and migrator; 0.8.25 with 999999 for the vault; 0.8.19 with 999999 for attestations. All omit the bytecode hash. The config selects Cancun like the pin; Forge caps the effective target at London for 0.8.15 and Paris for 0.8.19. The vault uses Cancun.

Deployment checks version() for all eight implementations. `DeployBridges` also deploys the no-argument migrator. Scripts write nine addresses to `config/<network>/addresses.json`: `optimismMintableERC721Factory`, `operatorFeeVault`, `schemaRegistry`, `eas`, `l2CrossDomainMessenger`, `l2StandardBridge`, `optimismMintableERC20Factory`, `l2ERC721Bridge`, and `legacyMigrator`. Commit that file and task-scoped `records/`. Never substitute local fork deployment addresses.

## Generate validations

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

The implementation-file guard requires all nine non-zero addresses before validation, approval or execution. The signing simulation checks eight L1 deposits and replays the eight L2 calls. Each deposit buys 300000 L2 gas. Cold fork measurements for the migrations were 56638 for the messenger, 54241 for the standard bridge, 51801 for the ERC20 factory and 74150 for the ERC721 bridge, before intrinsic gas. Each migration calldata is 324 bytes, bounding ordinary intrinsic gas at 26184 even if every byte were non-zero. The limit exceeds twice the heaviest call plus intrinsic calldata overhead, with room for storage metering differences between fork simulation and independent transactions.

Review `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Replace generated descriptive placeholders. For this testnet invocation remove any generated `taskOriginConfig` and set `skipTaskOriginValidation` to `true`. No task-origin signatures are required. Commit validations before asking signers to sign.

Update task-root `status.json` as authoring, validation and signing progress. Keep signature counts current. Share `config/<network>/README.md` with signers.

## Approve and execute

```bash
SIGNATURES=<base-signatures> make TASK_NETWORK=<network> approve-cb
SIGNATURES=<security-council-signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

Confirm all eight deposits succeed on L2, not just that the L1 transaction succeeds. Check all implementation addresses and versions against validations. Check the four migrated proxies have initializer version 1 and initializing false; messenger counterpart, nonce and raw idle sender at slot 204; standard bridge messenger and L1 counterpart; ERC20 factory bridge; ERC721 bridge messenger and L1 counterpart. Check the ERC721 factory, operator vault and EAS configuration too. Never retry an already successful migration blindly: the replay guards deliberately reject changed slot-0 state. Investigate any failed deposit before preparing a replacement task payload.

Commit task-scoped records. Finalize the signer README and task-root status together, then run `make check-task-status` from the repository root. Do not archive while an intended invocation remains pending.
