# Update Denim Verifier Hashes

Status: READY TO SIGN

## Description

Redeploys Zeronet's game type 621 `AggregateVerifier` `0.3.0` with new TEE and ZK proof program hashes,
then registers it in the `DisputeGameFactory`. The new provers pass each game's intermediate block
interval to the enclave and the ZK range program instead of a hardcoded 300, which changes the
enclave image and the ZK programs. Every other constructor value is copied from the current
verifier, including the 600 / 30 and 6000 / 300 proposal intervals.

No ETH moves and existing dispute games are unchanged.

## Targets

| Contract | Address |
| -- | -- |
| `DisputeGameFactory` proxy | `0xd930E0CebD52d7C77b8f900De242e818506C5474` |
| Current `AggregateVerifier` (`0.3.0`) | `0x7ce3766537e065dAaF0370799e2761B52569aFe6` |
| New `AggregateVerifier` (`0.3.0`) | TBD |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
