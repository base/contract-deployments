# Denim upgrade

Status: READY TO SIGN

## Description

Prepares Base Sepolia for the Denim hardfork in one transaction:

- registers `AggregateVerifier` `0.3.0` for game type 621 in the `DisputeGameFactory`. It switches the
  proposal intervals from 600 / 30 to 6000 / 300 blocks at Denim, when blocks go from 2s to 200ms, and
  carries the Denim proof program hashes with the per-game intermediate block interval fix;
- schedules Denim (upgrade id 13) in `ProtocolVersions` for October 21, 2026 at 18:00 UTC and raises
  the minimum protocol version from v1.4.0 to v1.5.0;
- sends five separate `OptimismPortal` deposits to the L2 `ProxyAdmin`, upgrading
  `L2ToL1MessagePasser` to `1.2.0`, `L1Block` to `1.8.0` and `SequencerFeeVault`, `BaseFeeVault`,
  `L1FeeVault` to `1.6.0`. The vaults keep their recipient, 2 ETH minimum withdrawal and L2 withdrawal
  network. The deposits execute shortly after the L1 transaction, independently of Denim activation.

The two L1 calls and five deposits run in one owner-Safe transaction. No ETH moves and existing
dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` |
| `ProtocolVersions` proxy | `0x15B721B12CF3b0C4400c8a2935A0Ae391c2eF65b` |
| Current `AggregateVerifier` (`0.2.0`) | `0xd702aaE6221f36Dfe7e8EBC4315D64344A9dB4CB` |
| New `AggregateVerifier` (`0.3.0`) | Not yet deployed; fill in after deployment |
| `OptimismPortal` proxy | `0x49f53e41452C74589E85cA1677426Ba426459e85` |
| L2 `ProxyAdmin` | `0x4200000000000000000000000000000000000018` |
| `L2ToL1MessagePasser` proxy | `0x4200000000000000000000000000000000000016` |
| `L1Block` proxy | `0x4200000000000000000000000000000000000015` |
| `SequencerFeeVault` proxy | `0x4200000000000000000000000000000000000011` |
| `BaseFeeVault` proxy | `0x4200000000000000000000000000000000000019` |
| `L1FeeVault` proxy | `0x420000000000000000000000000000000000001a` |
| New `L2ToL1MessagePasser` (`1.2.0`) | Filled in after deployment |
| New `L1Block` (`1.8.0`) | Filled in after deployment |
| New `SequencerFeeVault` (`1.6.0`) | Filled in after deployment |
| New `BaseFeeVault` (`1.6.0`) | Filled in after deployment |
| New `L1FeeVault` (`1.6.0`) | Filled in after deployment |

The facilitator must deploy all six implementations and generate validation files before signing.
The Security Council approves this combined transaction once.

## Sign

From the repository root:

```bash
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-07-denim-upgrade` for Sepolia, sign, and send the signature to the facilitator.
