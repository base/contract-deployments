# Update Cobalt Verifier Hashes

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x4558683a4689db8d1924af4a8be6562c8aaa1ef485e1f645298bfb506e83900e)

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
| New `AggregateVerifier` | `0x90ab3A3a747a60EF56919574dA1766F20ACEe21C` |

The new verifier was [deployed](https://hoodi.etherscan.io/tx/0xc9559e196f8cdf49bbeb87fe16e6434dc1cef4e6397a476ce80ee658ce9bb81c).

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
