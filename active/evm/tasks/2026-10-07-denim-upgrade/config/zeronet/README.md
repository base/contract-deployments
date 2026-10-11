# Denim Upgrade

Status: READY TO SIGN

## Description

Prepares Zeronet for the Denim hardfork in one transaction:

- registers `AggregateVerifier` `0.3.0` for game type 621 in the `DisputeGameFactory`. It switches the
  proposal intervals from 600 / 30 to 6000 / 300 blocks at Denim, when blocks go from 2s to 200ms, and
  carries the Denim proof program hashes;
- schedules Denim (upgrade id 13) in `ProtocolVersions` for October 14, 2026 at 18:00 UTC and raises
  the minimum protocol version from v1.4.0 to v1.5.0.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd930E0CebD52d7C77b8f900De242e818506C5474` |
| `ProtocolVersions` proxy | `0x30e172aaC675c9fe5A64792F92C9fD4d3E7cA9Da` |
| Current `AggregateVerifier` (`0.2.0`) | `0x90ab3A3a747a60EF56919574dA1766F20ACEe21C` |
| New `AggregateVerifier` (`0.3.0`) | TBD |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
