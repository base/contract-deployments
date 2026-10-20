# Remaining L2 predeploy upgrades

This task upgrades eight predeploys through eight separate L1 deposits to the L2 ProxyAdmin. The L1 ProxyAdmin owner's L2 alias must own the L2 ProxyAdmin. The scripts enforce the supported L1 and L2 chain IDs. Every Make command requires command-line `TASK_NETWORK`.

For the messenger, standard bridge, ERC20 factory and ERC721 bridge, each deposit calls `ProxyAdmin.upgradeAndCall(proxy, migrator, migrate(newImpl, initData))`. The task-local migrator resets legacy initializer state, installs the final implementation and calls its `initialize(address)` in the proxy's context. A failed L2 call reverts the whole upgradeAndCall, leaving the old implementation and storage intact.

BaseTime is excluded from this task. Execution is independent of Denim activation and has no timestamp guard. EAS changes its delegated-signature domain version to 1.3.0, invalidating outstanding signatures for 1.2.0.

Run from this task directory. Replace `<network>` with the configured network; the Makefile rejects unsupported networks.

## Prepare and simulate

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> build
make TASK_NETWORK=<network> simulate-l2
```

Review `config/<network>/.env` against fresh live reads. The shared fork replay rejects changed legacy slot-0 values, counterparts, factory configuration, vault configuration or owner, an initialized operator vault, and a messenger whose sender is not the idle default. It checks all implementations, versions, initializer flags and configuration after replay, and preserves the messenger nonce, idle sender and vault totalProcessed. Tests also preserve message, deposit, schema, attestation and factory records; create an ERC20 token and exercise bridge mint/burn; and prove failed migrations roll back on all four proxies. The L1 test exercises MultisigScript's signer simulation and the same L2 post-check with local implementations persisted across forks. No test broadcasts.

If the configured L1 RPC is unavailable, select an alternative explicitly with `L1_RPC_URL=<url>` on any command. `config/<network>/.env` selects the L2 RPC.

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

The implementation-file guard requires all nine non-zero addresses before validation, approval or execution. The signing simulation checks eight L1 deposits and replays the eight L2 calls. Each deposit buys 300000 L2 gas.

Review `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Replace generated descriptive placeholders. For this testnet invocation remove any generated `taskOriginConfig` and set `skipTaskOriginValidation` to `true`. No task-origin signatures are required. Commit validations before asking signers to sign.

Update task-root `status.json` as authoring, validation and signing progress. Keep signature counts current. Share `config/<network>/README.md` with signers.

## Approve and execute

```bash
SIGNATURES=<base-signatures> make TASK_NETWORK=<network> approve-cb
SIGNATURES=<security-council-signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

Confirm all eight deposits succeed on L2, not just that the L1 transaction succeeds. Check all implementation addresses and versions against validations. Check the four migrated proxies have initializer version 1 and initializing false; messenger counterpart, nonce and raw idle sender; standard bridge messenger and L1 counterpart; ERC20 factory bridge; ERC721 bridge messenger and L1 counterpart. Check the ERC721 factory, operator vault and EAS configuration too. Never retry an already successful migration blindly: the replay guards deliberately reject changed slot-0 state. Investigate any failed deposit before preparing a replacement task payload.

Commit task-scoped records. Finalize the signer README and task-root status together, then run `make check-task-status` from the repository root. Do not archive while an intended invocation remains pending.
