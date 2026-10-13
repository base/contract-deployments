# Pause signing

Each signer signs **20 pause transactions on EACH network** listed in the task's signer README. Signing one network does not cover another. Each batch uses 20 sequential nonces of that network's Incident Safe. Signing does not execute a transaction.

## Sign a network

Use the task revision and Ledger account agreed with the facilitator. Run these commands from `active/evm/tasks/<task-id>/`, replacing `<network>` with one of the task's configured networks:

```sh
make TASK_NETWORK=<network> deps-pause
make TASK_NETWORK=<network> sign-pause
```

If the facilitator specifies a different Ledger account, append `LEDGER_ACCOUNT=<account>` to both commands and every rerun.

Unlock the Ledger and open the Ethereum app. Approve each transaction when prompted. The recipe hides the signing tool's signature output. It installs and runs the pinned signing tool under the mise Go `GOROOT/bin`, without changing your global `GOBIN` or other tasks' installs.

On success, send the **contents of `config/<network>/signatures-pause.txt`** to the facilitator. Do not send terminal output or files from `.pause-signing/`. The completed file contains exactly 20 signatures. Repeat the commands for EACH remaining network.

## Retry a failed batch

The recipe retries the same nonce up to three times before stopping. It only saves a signature after a successful, valid signing response. A failed attempt cannot skip a nonce or add a duplicate signature.

If it stops, unlock the Ledger, open the Ethereum app, and run the same command with the same Ledger account:

```sh
make TASK_NETWORK=<network> sign-pause
```

Successful signatures remain in `config/<network>/.pause-signing/`. The rerun resumes at the first unsigned nonce. Do not delete this directory or send partial signatures. If the Safe nonce, network, Ledger account, or signing context has changed, the recipe refuses to combine old and new signatures. Contact the facilitator before restarting.

A completed `signatures-pause.txt` is never overwritten by a rerun. If a process was killed and left `.pause-signing.lock`, first confirm that no signing process is running for this task and network. Remove only that lock directory, then rerun the command above.

### Restart after a context change

Do not restart without the facilitator's explicit approval to abandon the old batch and use the new signing context.

1. Confirm that no signing process is running for this task and network. Agree with the facilitator on the new context and an unused backup path, replacing `<batch-id>` below with a unique identifier.
2. Preserve the entire checkpoint directory before restarting:

   ```sh
   mv config/<network>/.pause-signing config/<network>/.pause-signing-preserved-<batch-id>
   ```

   Check that the preserved directory contains the old `context` and saved signatures. Keep it until the facilitator approves its disposal. Do not send these partial signatures or copy them into the new batch.
3. If `config/<network>/.pause-signing.lock` remains, remove only that stale lock with `rmdir config/<network>/.pause-signing.lock`. Do not remove a lock while signing is running.
4. Use the facilitator-approved task revision, `config/<network>/.env`, and Ledger account, then run `make TASK_NETWORK=<network> sign-pause` again. Append `LEDGER_ACCOUNT=<account>` if required. The recipe creates a new `config/<network>/.pause-signing` and starts a fresh batch.

This is a manual recovery procedure, not an automatic reset. A completed `config/<network>/signatures-pause.txt` still blocks signing; do not remove it as part of this partial-batch recovery.

Task authors can find the include example and facilitator procedure in [FACILITATOR.md](FACILITATOR.md). This directory is shared code, not a live task.
