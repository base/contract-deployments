# Task facilitator guide

Replace the L1 `BalanceTracker`, point the L2 `FeeDisburser` at it, and move the `FeeDisburser` admin to the alias of `NEW_ADMIN`.

Run commands from this task directory and pass `TASK_NETWORK=<network>` on every Make command line. Inputs live in `config/<network>/.env`. Deployed addresses are written to `config/<network>/addresses.json`.

The work happens in three phases:

1. **Deploy on L1 from the facilitator's Ledger.** This deploys and initializes the new `BalanceTracker` proxy, then hands its admin to `NEW_ADMIN`.
2. **Deploy on L2 from the facilitator's Ledger.** This deploys the `FeeDisburser` implementation with `L1_WALLET` set to the new `BalanceTracker`.
3. **Multisig transaction from `OWNER_SAFE`.** This sends two `OptimismPortal` deposits to the `FeeDisburser` proxy: `upgradeTo(new implementation)`, then `changeAdmin(NEW_ADMIN_L2_ALIAS)`.

## Install dependencies

```sh
make TASK_NETWORK=<network> deps
```

## Deploy

Use the Ledger account at `LEDGER_ACCOUNT`; it needs gas on both L1 and L2. Each script simulates and checks its output before broadcasting:

- `deploy-l1` checks the new proxy's admin, implementation, profit wallet, system addresses and targets, and that neither the proxy nor the implementation can be reinitialized.
- `deploy-l2` runs `disburseFees()` through the live `FeeDisburser` proxy with the new implementation against the live fee vaults.

```sh
make TASK_NETWORK=<network> deploy-l1
make TASK_NETWORK=<network> deploy-l2
```

Commit `config/<network>/addresses.json` and the task-scoped `records/`. Each target refuses to run again once its address is recorded.

## Generate validation files

```sh
make TASK_NETWORK=<network> gen-validation
```

This writes `config/<network>/validations/base-signer.json` for `OWNER_SAFE`. The post-check replays both deposits as the alias of `OWNER_SAFE` on an L2 fork. It then asserts the new implementation, the new admin, the new `L1_WALLET`, and an unchanged `lastDisbursementTime`.

Check the state diff and replace any summary placeholders. Commit the validation, set the network step to `ready_to_sign`, then `collecting`, and update the `base` signature count in `status.json` as signatures arrive.

## Execute

Confirm the live threshold and nonce of `OWNER_SAFE`, then order the signatures by owner address and concatenate them. Set the step to `ready_to_execute`, then run:

```sh
make TASK_NETWORK=<network> execute SIGNATURES=<concatenated-signatures>
```

After the deposits are relayed on L2, run:

```sh
make TASK_NETWORK=<network> verify-l2
```

Commit the final artifacts. Set `Status: EXECUTED` with the L1 transaction link in `config/<network>/README.md`, and update the step, `executed_tx`, and `last_updated` in `status.json` in the same change. Then update `BALANCE_TRACKER` in `config/<network>.env` at the repository root to the new proxy.

## Archive

Keep the task active until every intended network is executed or canceled. From the repository root, run `make check-task-status`, then `make archive-task` and select this task.
