# Upgrade Sepolia `FeeDisburser`

Status: READY TO SIGN

## Description

Upgrade Base Sepolia `FeeDisburser` to version `1.1.0`, which can refund configured L2 system addresses before bridging remaining fees to L1.

## Changes

- Deploy the `FeeDisburser` implementation.
- Upgrade the L2 proxy through an L1-to-L2 deposit transaction.
- Initialize the L2 system-address refund configuration with empty arrays.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
