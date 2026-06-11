# Upgrade Mainnet `BalanceTracker` system addresses

Status: [EXECUTED](https://etherscan.io/tx/0x282f780a9ed3150ca949f0bf116e2ec9e77400550c2fe7cc7ad313fa5e9218e8)

## Description

Upgrade the L1 [`BalanceTracker`](https://etherscan.io/address/0x23B597f33f6f2621F77DA117523Dffd634cDf4ea) so it tops up the new proposer, challenger, and registrar addresses (part of the multi-proof rollout) in addition to the existing batch sender.

`systemAddresses` / `targetBalances` can only be set through `initialize`, which is guarded by `reinitializer(3)`. The proxy is currently at initialized version 2, so this task points the proxy at a freshly deployed implementation and re-initializes it in the same call via `Proxy.upgradeToAndCall`. The call is executed by the CB Incident multisig (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`), which is the proxy admin.

After execution the system addresses and target balances are:

| Role | Address | Target balance |
| -- | -- | -- |
| Batch sender | `0x5050f69a9786f081509234f1a7f4684b5e5b76c9` | 550 ETH |
| Proposer | `0xc1366Fabe614d42D367A1ecE61821238A1d31cF5` | 25 ETH |
| Challenger | `0x819501cdA743a606A93dbEF254FE0D263Ce7d102` | 5 ETH |
| Registrar | `0xd87488Dbb5b6F47cc6c15Dd95Bb60c83D3031b04` | 5 ETH |

## Approving the transaction

### 1. Update repo:

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool (NOTE: do not enter the task directory. Run this command from the project's root).

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Be sure to select the correct task from the list of available tasks to sign.

Task name: `mainnet/2026-06-09-upgrade-balance-tracker`

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
