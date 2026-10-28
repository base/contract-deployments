# 2026-10-21-replace-balance-tracker

Status: EXECUTED
https://sepolia.etherscan.io/tx/0x1d9e7be871ea17c1fc215940e01c19dfabbb67ace76d83275ac72f0609096789

## Description

The Sepolia `BalanceTracker` is admined by an inaccessible EOA, so a new `BalanceTracker` has been deployed on L1 at `0x5D744AeA3e41B525948f000B5588Df291B47C420`, with `0x646132A1667ca7aD00d36616AFBA1A28116C770A` as its proxy admin and profit wallet. It refills the proposer to 200 ETH and the batcher to 1000 ETH.

This transaction from `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f` sends two `OptimismPortal` deposits to the Base Sepolia `FeeDisburser` proxy `0x76355A67fCBCDE6F9a69409A8EAd5EaA9D8d875d`:

1. `upgradeTo` the new implementation `0xdC3e4dB1947F57fB18b093924Ca95B96ddc1ef2e`, whose `L1_WALLET` is the new `BalanceTracker`.
2. `changeAdmin` to `0x757232a1667ca7ad00D36616aFbA1A28116c881B`, the L2 alias of `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.

## Sign

From the repository root:

```sh
make TASK_NETWORK=sepolia sign-task
```

Select `2026-10-21-replace-balance-tracker` for sepolia, sign, and send the signature to the facilitator.
