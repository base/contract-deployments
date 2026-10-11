# Denim SystemConfig Gas Parameters

Status: READY TO SIGN

## Description

Sets Zeronet's post-Denim gas parameters on `SystemConfig`:

- gas limit from `1,200,000,000` to `120,000,000`;
- EIP-1559 denominator from `100` to `1000`.

The node already applies these values from the first Denim block; this writes them to L1. Executes
after Denim activates on October 14, 2026 at 18:00 UTC.

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
