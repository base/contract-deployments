# Denim SystemConfig gas parameters

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x1626e1dcefdf7d5a842c3895108e89ea24f12cc5e53ff34dc73bd460eeb4cf2d)

## Description

Sets Sepolia's post-Denim gas parameters on `SystemConfig`:

- gas limit from `1,200,000,000` to `120,000,000`;
- EIP-1559 denominator from `100` to `1000`.

Sign this task before Denim activates. Execute only after Sepolia Denim activates on
October 21, 2026 at 18:00 UTC (timestamp `1792605600`). The node applies these values from
the first Denim block; this task writes them to L1.

## Target

| Contract | Address |
| -- | -- |
| `SystemConfig` | `0xf272670eb55e895584501d564AfEB048bEd26194` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
