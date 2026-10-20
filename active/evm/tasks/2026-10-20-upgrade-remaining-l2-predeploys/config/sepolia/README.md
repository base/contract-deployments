# Remaining L2 predeploy upgrades

Status: READY TO SIGN

Upgrades eight Base Sepolia predeploys to base/contracts v8.4.0. The L1 ProxyAdmin owner sends eight separate deposits through the OptimismPortal to the L2 ProxyAdmin. Its L2 alias owns that ProxyAdmin. No ETH is transferred.

| Predeploy | Address | Current | New |
| --- | --- | --- | --- |
| OptimismMintableERC721Factory | `0x4200000000000000000000000000000000000017` | 1.3.0 | 1.4.2 |
| OperatorFeeVault | `0x420000000000000000000000000000000000001b` | 1.0.0 | 1.1.0 |
| SchemaRegistry | `0x4200000000000000000000000000000000000020` | 1.2.0 | 1.3.1-beta.2 |
| EAS | `0x4200000000000000000000000000000000000021` | 1.2.0 | 1.4.1-beta.3 |
| L2CrossDomainMessenger | `0x4200000000000000000000000000000000000007` | 1.6.0 | 2.2.0 |
| L2StandardBridge | `0x4200000000000000000000000000000000000010` | 1.3.0 | 1.13.0 |
| OptimismMintableERC20Factory | `0x4200000000000000000000000000000000000012` | 1.4.0 | 1.10.2 |
| L2ERC721Bridge | `0x4200000000000000000000000000000000000014` | 1.3.0 | 1.10.0 |

The operator vault is initialized atomically, preserving its BaseFeeVault recipient, zero minimum and L2 withdrawal network. The factory keeps its ERC721 bridge and Sepolia L1 chain ID. Existing schema and attestation storage is preserved. EAS changes its signing domain version from 1.2.0 to 1.3.0, so outstanding delegated signatures need to be regenerated.

Execution is independent of Denim activation on October 21, 2026 at 18:00 UTC. These eight contracts do not use BaseTime or new L1Block fields, and Denim does not replace them. BaseTime is excluded so Denim can install its canonical implementation.

The messenger, standard bridge, ERC20 factory and ERC721 bridge each use a task-local migrator in one atomic upgradeAndCall. It resets only the legacy initializer slot, installs the new implementation and initializes its live counterparts. If initialization fails, the entire L2 call reverts and the old implementation and storage remain intact.

The facilitator must deploy all eight implementations and the migrator, then commit `addresses.json` and validation files before signatures are collected. Base signers require 3 signatures; the Security Council requires 1.

From the repository root:

```bash
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-20-upgrade-remaining-l2-predeploys` for Sepolia and send the signature to the facilitator.
