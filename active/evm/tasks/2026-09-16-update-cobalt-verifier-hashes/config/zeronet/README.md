# Update Cobalt Verifier Hashes

Status: READY TO SIGN

## Description

Redeploys Zeronet's game type 621 `AggregateVerifier` with updated TEE and ZK proof program hashes,
then registers it in the `DisputeGameFactory`. Every other constructor value is copied from the
currently registered verifier.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd930E0CebD52d7C77b8f900De242e818506C5474` |
| Current `AggregateVerifier` | `0x2504B1c3B78B2711e24eadF7eA077b0cA1b91859` |

The new `AggregateVerifier` address will be recorded in [`addresses.json`](addresses.json) after
deployment.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
