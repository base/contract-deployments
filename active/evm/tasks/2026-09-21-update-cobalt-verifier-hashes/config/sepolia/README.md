# Update Cobalt Verifier Hashes

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x05b717b61373eb5ec92ee4ad7c6db7556f3400a477246035dbfdd20c5f979ca3)

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
| New `AggregateVerifier` | `0xd702aaE6221f36Dfe7e8EBC4315D64344A9dB4CB` |

The new verifier was [deployed](https://sepolia.etherscan.io/tx/0x72391a548074f066d7c138b309dbd8284f412bea515ec47ae17c7cf27524e04f).

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
