# 2026-10-21-replace-balance-tracker

Status: READY TO SIGN

## Description

The Sepolia `BalanceTracker` is admined by an inaccessible EOA, so a new `BalanceTracker` has been deployed on L1 with `0x646132A1667ca7aD00d36616AFBA1A28116C770A` as its proxy admin and profit wallet. It refills the proposer to 200 ETH and the batcher to 1000 ETH.

This transaction from `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f` sends two `OptimismPortal` deposits to the Base Sepolia `FeeDisburser` proxy `0x76355A67fCBCDE6F9a69409A8EAd5EaA9D8d875d`:

1. `upgradeTo` a new implementation whose `L1_WALLET` is the new `BalanceTracker` (see `addresses.json`).
2. `changeAdmin` to `0x757232a1667ca7ad00D36616aFbA1A28116c881B`, the L2 alias of `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.

## Sign

From the repository root:

```sh
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-21-replace-balance-tracker` for sepolia, sign, and send the signature to the facilitator.
