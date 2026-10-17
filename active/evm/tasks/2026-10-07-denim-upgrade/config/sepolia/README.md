# Denim upgrade

Status: READY TO SIGN

## Description

Prepares Base Sepolia for the Denim hardfork in one transaction:

- registers `AggregateVerifier` `0.3.0` for game type 621 in the `DisputeGameFactory`. It switches the
  proposal intervals from 600 / 30 to 6000 / 300 blocks at Denim, when blocks go from 2s to 200ms, and
  carries the Denim proof program hashes with the per-game intermediate block interval fix;
- schedules Denim (upgrade id 13) in `ProtocolVersions` for October 21, 2026 at 18:00 UTC and raises
  the minimum protocol version from v1.4.0 to v1.5.0.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` |
| `ProtocolVersions` proxy | `0x15B721B12CF3b0C4400c8a2935A0Ae391c2eF65b` |
| Current `AggregateVerifier` (`0.2.0`) | `0xd702aaE6221f36Dfe7e8EBC4315D64344A9dB4CB` |
| New `AggregateVerifier` (`0.3.0`) | Not yet deployed; fill in after deployment |

The facilitator must deploy the new verifier and generate validation files before signing.

## Sign

From the repository root:

```bash
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-07-denim-upgrade` for Sepolia, sign, and send the signature to the facilitator.
