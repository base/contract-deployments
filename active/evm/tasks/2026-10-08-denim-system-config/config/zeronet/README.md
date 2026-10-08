# Denim SystemConfig Gas Parameters

Status: READY TO SIGN

## Description

Records Zeronet's post-Denim gas parameters in `SystemConfig`:

- gas limit from `1,200,000,000` to `120,000,000`;
- EIP-1559 denominator from `100` to `1000`.

Denim drops the L2 block time from 2s to 200ms, and at its first block the node already applies these
values itself to keep gas throughput and base-fee responsiveness per second. This transaction writes
the same values to L1 so a later `SystemConfig` update does not restore the 2s-block ones. It does
not change how the chain runs, and must execute after Denim activates on October 14, 2026 at
18:00 UTC.

## Target

| Contract | Address |
| -- | -- |
| `SystemConfig` | `0x0a111C7980152bDe41D71f48e2E1d8184f5f6187` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
