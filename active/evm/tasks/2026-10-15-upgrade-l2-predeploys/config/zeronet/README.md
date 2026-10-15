# Upgrade L2 Predeploys

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x50c7bd1ee23ffa011dae50eebe1ea32ebf30a64e92e55214688afcbc6e2368a0)

## Description

Upgrades five Zeronet L2 predeploys to their base/contracts v8.4.0 implementations, through deposit
transactions from the ProxyAdmin owner to the L2 ProxyAdmin:

| Predeploy | Address | Version |
| -- | -- | -- |
| `L2ToL1MessagePasser` | `0x4200000000000000000000000000000000000016` | 1.1.2 → 1.2.0 |
| `L1Block` | `0x4200000000000000000000000000000000000015` | 1.7.0 → 1.8.0 |
| `SequencerFeeVault` | `0x4200000000000000000000000000000000000011` | 1.5.1 → 1.6.0 |
| `BaseFeeVault` | `0x4200000000000000000000000000000000000019` | 1.5.1 → 1.6.0 |
| `L1FeeVault` | `0x420000000000000000000000000000000000001A` | 1.5.1 → 1.6.0 |

The fee vaults are initialized during the upgrade with recipient
`0x3d59999977e0896ee1f8783bB8251DF16fb483E9`, a 10 ETH minimum withdrawal, and withdrawals to L1.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
