# Facilitator Guide

Guide for updating the Base Sepolia `BalanceTracker` profit wallet.

## 1. Install dependencies and verify current state

Run every task command with the network selected explicitly:

```bash
cd active/evm/tasks/2026-08-25-update-sepolia-balance-tracker-profit-wallet
make TASK_NETWORK=sepolia deps
make TASK_NETWORK=sepolia verify-current
```

Review the task-specific addresses in `config/sepolia/addresses.json`. The
shared `BalanceTracker` proxy address comes from the repository's
`config/sepolia.env`.

## 2. Deploy the implementation

Connect the Ledger account for `PROXY_ADMIN`, then run:

```bash
make TASK_NETWORK=sepolia deploy
```

This deploys a `BalanceTracker` implementation whose immutable `PROFIT_WALLET`
is the company wallet used on mainnet. It adds
`balanceTrackerImplementation` to `config/sepolia/addresses.json`. Review and
commit:

- `config/sepolia/addresses.json`
- the deployment record under `records/DeployBalanceTracker.s.sol/11155111/`

## 3. Execute the upgrade

The existing proxy admin is an EOA, not a Safe, so this task does not generate a
signer validation file or collect multisig approvals. The connected
`PROXY_ADMIN` Ledger executes the upgrade directly:

```bash
make TASK_NETWORK=sepolia upgrade
```

The script verifies that the proxy implementation and profit wallet change
while both existing system addresses and target balances remain unchanged.

## 4. Verify and archive

```bash
make TASK_NETWORK=sepolia verify
```

Set `Status: [EXECUTED](<transaction-url>)` in
`config/sepolia/README.md`, commit the upgrade record, then run
`make archive-task` from the repository root.
