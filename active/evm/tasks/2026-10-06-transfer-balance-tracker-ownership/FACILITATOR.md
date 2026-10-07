# Facilitator Guide

Guide for moving the `BalanceTracker` proxy admin from the current EOA to the Coinbase multisig.

The current admin is an EOA, not a Safe, so this task has no signer validation file, no multisig
approvals and no task-origin signatures. The `CURRENT_ADMIN` Ledger sends the transaction directly.

## 0. Ordering

The Sepolia `BalanceTracker` profit-wallet upgrade
([#768](https://github.com/base/contract-deployments/pull/768)) is executed by the same EOA admin.
Execute that upgrade before this task, or confirm it has been abandoned. After this transfer, the
upgrade must go through the multisig instead.

## 1. Install dependencies and simulate

```bash
cd active/evm/tasks/2026-10-06-transfer-balance-tracker-ownership
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> sim
```

The simulation must show a single `changeAdmin(NEW_ADMIN)` call on `BalanceTracker` emitting
`AdminChanged(CURRENT_ADMIN, NEW_ADMIN)`. The script reverts if the current admin is not
`CURRENT_ADMIN`, if `NEW_ADMIN` has no code, or if the admin does not change.

## 2. Execute

Connect the Ledger for `CURRENT_ADMIN` (see `config/<network>/.env`). If it is not at the default
derivation index, append `LEDGER_ACCOUNT=<index>`.

```bash
make TASK_NETWORK=<network> execute
```

## 3. Verify and archive

```bash
make TASK_NETWORK=<network> verify
```

Set `Status: [EXECUTED](<transaction-url>)` in `config/<network>/README.md`, commit the record
under `records/`, then run `make archive-task` from the repository root.
