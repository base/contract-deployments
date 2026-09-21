# Update Cobalt Verifier Hashes

Status: READY TO SIGN

## Description

Redeploys Sepolia's game type 621 `AggregateVerifier` with updated TEE and ZK proof program hashes,
then registers it in the `DisputeGameFactory`. Every other constructor value is copied from the
currently registered verifier.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` |
| Current `AggregateVerifier` | `0xC1a5aCb64e439A04017A526e3D8E5d3e79846448` |

The new verifier address is recorded in `addresses.json` after deployment.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
