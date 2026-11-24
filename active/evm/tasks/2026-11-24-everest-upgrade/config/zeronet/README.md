# Everest Upgrade

Status: READY TO SIGN

## Description

Prepares Zeronet for the Everest hardfork in one transaction:

- registers a new `AggregateVerifier` `0.3.0` for game type 621 in the `DisputeGameFactory`, carrying the
  Everest proof program hashes. Every other immutable matches the current verifier;
- schedules Everest (upgrade id 14) in `ProtocolVersions` for `<date> UTC` and raises the minimum protocol
  version from v1.5.0 to v1.6.0.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd930E0CebD52d7C77b8f900De242e818506C5474` |
| `ProtocolVersions` proxy | `0x30e172aaC675c9fe5A64792F92C9fD4d3E7cA9Da` |
| Current `AggregateVerifier` | `0x50521128e3eB8708F05129D7B7283737D55a1936` |
| New `AggregateVerifier` | `<deployed address>` |

## Sign

From the repository root:

```sh
make TASK_NETWORK=zeronet sign-task
```

Select `2026-11-24-everest-upgrade` for zeronet, sign, and send the signature to the facilitator.
