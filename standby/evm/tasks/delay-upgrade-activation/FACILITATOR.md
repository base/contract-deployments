# Delay an upgrade activation

Run this operation directly from `standby/evm/tasks/delay-upgrade-activation/`. Replace `<network>` on every command. Do not copy the task into active, or edit its Makefile, Solidity, or this guide for an incident.

## Freshness review

Before invoking, confirm the target ABI and hash-chain semantics still match the reviewed `ProtocolVersions` implementation. Confirm its live `incidentResponder()` is the intended Base/incident Safe, including its owners and threshold. A change to the target ABI, ownership or responder role, `BASE_CONTRACTS_COMMIT`, or signing workflow requires another review of the canonical task before collecting signatures. The reviewed contracts pin is `385f21a41f277d287db92fffe88dca41299162ea`.

This flow calls the responder directly. It does not go through the ProxyAdmin owner, needs no Security Council approval, and needs no task-origin signatures, including on mainnet. The generated validation explicitly skips task-origin validation. The signer tool still validates the simulation and transaction hashes.

## Configure and prepare

Create only `config/<network>/.env` and `config/<network>/README.md`. The global `config/<network>.env` supplies RPC, Ledger account, and `PROTOCOL_VERSIONS_PROXY`. Use an invocation-specific proxy override only for a different deployment. Do not put `RECORD_STATE_DIFF` in the task `.env`; the signer tool injects it.

The invocation `.env` must contain these values, with decimal upgrade ID and Unix timestamps:

```dotenv
BASE_CONTRACTS_COMMIT=<reviewed-contracts-commit>
UPGRADE_ID=<registered-upgrade-id>
EXPECTED_CURRENT_TIMESTAMP=<current-onchain-activation-timestamp>
NEW_TIMESTAMP=<later-activation-timestamp>
```

The signer README must start with a title and `Status: READY TO SIGN`. Briefly state the network, upgrade ID, old and new UTC times, why the delay is needed, and the intended responder Safe. Do not change canonical files. Keep any network-specific addresses and artifacts in `config/<network>/`.

```sh
make TASK_NETWORK=<network> prepare
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> build
make TASK_NETWORK=<network> validate
make TASK_NETWORK=<network> gen-validation-cb
```

`prepare` checks configuration without contacting RPC. `validate` runs read-only prechecks. `gen-validation-cb` simulates exactly one zero-value `delayTimestamp(id,newTimestamp)` call from the live responder and writes `config/<network>/validations/base-signer.json`. Inspect the full schedule and commitment in the simulation, including successors for non-tail IDs. Confirm only the selected activation changes and responder and schedule length stay unchanged. Commit the invocation configuration and validation before signing.

## Sign and execute

```sh
make TASK_NETWORK=<network> sign-task
```

Choose the network, this standby operation, and `Base Signer` in the signer UI. Only JSON validations make a standby invocation discoverable. Review the hashes and state diff. Collect the responder Safe's threshold of signatures and concatenate them in Safe owner-address order.

```sh
make TASK_NETWORK=<network> execute SIGNATURES=<concatenated-signatures>
make TASK_NETWORK=<network> verify
```

`execute` runs pre/postchecks and submits through the responder Safe. It rejects a frozen or activated target, a stale expected timestamp, insufficient notice, or crossing the next scheduled activation. Re-simulate and regenerate validation if the schedule, Safe nonce, or role changes; recollect signatures when the transaction hash changes. `verify` checks the new timestamp, full live schedule commitment, and responder against global `INCIDENT_MULTISIG`. Confirm that global value matches the live role during freshness review. Compare the execution state diff with the signed validation to verify unchanged schedule length and other timestamps.

Forge broadcasts belong to task-scoped `records/<script>/<chain-id>/`. Do not move them into a network config. Mark each invocation `Status: EXECUTED` with its transaction link, or `Status: CANCELED` with the reason on a separate line. Commit every final validation, signature, address artifact, and execution record.

## Archive the invocation

Archive only after every network configuration under this operation is executed or canceled. Shared task-scoped records cannot safely be split by network. A pending sibling invocation blocks archival without deleting any files.

Keep the operational PR unmerged until all intended invocations are executed or canceled and the dated archive, final artifacts, and standby invocation removals are committed. On `main`, canonical standby must remain unchanged and contain no invocation-specific data before and after merge.

Fetch main before running the archive command. `TASK_DATE` is the incident's UTC date in `YYYY-MM-DD` form:

```sh
make TASK_NETWORK=<network> archive-task TASK_DATE=<YYYY-MM-DD>
```

The command compares canonical task files byte-for-byte with `origin/main`, refuses an existing destination, and snapshots every finalized network and all artifacts into `archive/evm/<YYYY-MM-DD>-delay-upgrade-activation/`. The archive includes canonical scripts and guide, Foundry configuration, and each network's global configuration snapshot. Only `config/`, `signatures/`, and `records/` are removed from standby. Canonical files remain identical for the next invocation. Commit the archive and invocation removals together. Archived tasks are historical and must not be edited or executed.
