# Update Batcher and Proposer addresses in L1 for sSepolia-alpha

Status: ready to execute

## Objective

We are updating batcher and proposer addresses for sepolia-alpha to keys that are managed by internal key management service.

This runbook implements scripts which allow system owner to execute: 
1. `UpdateBatcherHash` -- Updates the batcher hash in `SystemConfig` to be the new key.
2. `RollbackBatcherHash` -- Rollback the batcher upgrade.
3. `UpdateProposer` -- Upgrades `PermissionedDisputeGame` contract to have the new proposer.
4. `RollbackProposer` -- Rollback the proposer upgrade.

The values we are sending are statically defined in the `.env`.

# 1. Update repo and move to the appropriate folder:
```
cd contract-deployments
git pull
cd sepolia-alpha/2024-08-21-update-batcher-proposer
make deps
```

# 2. Batcher update
## 2.1. Simulate and validate the transaction

``` shell
make execute-update-batcher
```

If the private-key is the owner (or via `vm.prank`), it should start the foundry simulation. The logs should be
```
== Logs ==
  Current batcherHash: 
  0x000000000000000000000000212dd524932bc43478688f91045f2682913ad8ee
  New batcherHash: 
  0x0000000000000000000000007a43fd33e42054c965ee7175dd4590d2bdba79cb
```

## 2.2. Execute the transaction

Once the tx is simulated and validated, modify the `Makefile` to add the owner's private key and `--broadcast` to the `execute` command.

## 2.3. Rollback (if needed)

If somehow we need to rollback, we can do the same simulation and execution step as above, but for `make execute-rollback-batcher`.

# 3. Proposer update
## 3.1. Simulate and validate the transaction

``` shell
make execute-update-proposer
```

If the private-key is the owner (or via `vm.prank`), it should start the foundry simulation. The logs should be
```
== Logs ==
  Current proposer: 
  0xBcB04FC753D36dcEeBe9Df7E18E23c46D1fcEA3c
  Updated proposer to: 
  0xf99C2Da4822Af652fe1BF55F99713980efe5D261
```

## 3.2. Execute the transaction

Once the tx is simulated and validated, modify the `Makefile` to add the owner's private key and `--broadcast` to the `execute` command.

## 3.3. Rollback (if needed)

If somehow we need to rollback, we can do the same simulation and execution step as above, but for `make execute-rollback-proposer`.


