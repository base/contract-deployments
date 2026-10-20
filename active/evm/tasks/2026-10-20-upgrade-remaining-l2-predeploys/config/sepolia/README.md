# Remaining L2 predeploy upgrades

Status: READY TO SIGN

Upgrades four Base Sepolia predeploys to base/contracts v8.4.0. The L1 ProxyAdmin owner sends four separate deposits through the OptimismPortal to the L2 ProxyAdmin. Its L2 alias owns that ProxyAdmin. No ETH is transferred.

| Predeploy | Address | Current | New |
| --- | --- | --- | --- |
| OptimismMintableERC721Factory | `0x4200000000000000000000000000000000000017` | 1.3.0 | 1.4.2 |
| OperatorFeeVault | `0x420000000000000000000000000000000000001b` | 1.0.0 | 1.1.0 |
| SchemaRegistry | `0x4200000000000000000000000000000000000020` | 1.2.0 | 1.3.1-beta.2 |
| EAS | `0x4200000000000000000000000000000000000021` | 1.2.0 | 1.4.1-beta.3 |

The operator vault is initialized atomically, preserving its BaseFeeVault recipient, zero minimum and L2 withdrawal network. The factory keeps its ERC721 bridge and Sepolia L1 chain ID. Existing schema and attestation storage is preserved. EAS changes its signing domain version from 1.2.0 to 1.3.0, so outstanding delegated signatures need to be regenerated.

Execution is independent of Denim activation on October 21, 2026 at 18:00 UTC. These four contracts do not use BaseTime or new L1Block fields, and Denim does not replace them. BaseTime is excluded so Denim can install its canonical implementation.

The messenger, standard bridge, ERC721 bridge and ERC20 factory are excluded. Their live initializer version is 2, while v8.4.0 only accepts an uninitialized proxy. New required configuration slots are empty. Upgrading without initialization breaks their configuration, and upgradeAndCall reverts. They need a separate storage migration, not this task.

The facilitator must deploy implementations and commit `addresses.json` and validation files before signatures are collected. Base signers require 3 signatures; the Security Council requires 1.

From the repository root:

```bash
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-20-upgrade-remaining-l2-predeploys` for Sepolia and send the signature to the facilitator.
