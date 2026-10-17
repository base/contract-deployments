# Upgrade L2 Predeploys

Status: READY TO SIGN

## Description

Upgrades five Base Sepolia L2 predeploys to their base/contracts v8.4.0 implementations, through deposit
transactions from the ProxyAdmin owner to the L2 ProxyAdmin:

| Predeploy | Address | Version |
| -- | -- | -- |
| `L2ToL1MessagePasser` | `0x4200000000000000000000000000000000000016` | 1.1.0 → 1.2.0 |
| `L1Block` | `0x4200000000000000000000000000000000000015` | 1.7.0 → 1.8.0 |
| `SequencerFeeVault` | `0x4200000000000000000000000000000000000011` | 1.4.0 → 1.6.0 |
| `BaseFeeVault` | `0x4200000000000000000000000000000000000019` | 1.4.0 → 1.6.0 |
| `L1FeeVault` | `0x420000000000000000000000000000000000001A` | 1.4.0 → 1.6.0 |

The fee vaults are initialized during the upgrade with recipient
`0x76355A67fCBCDE6F9a69409A8EAd5EaA9D8d875d`, a 2 ETH minimum withdrawal, and withdrawals to L2,
unchanged from the live config.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
