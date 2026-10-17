# Rotate verifier hashes

From the repository root, run `make new-task STANDBY_OP=update-verifier-hashes TASK_NETWORK=<network>` to create `config/<network>/.env`, `config/<network>/README.md`, and task-root `status.json`. Then run directly from `standby/evm/tasks/update-verifier-hashes/`, replacing `<network>` on every command. Do not copy this operation into active or edit its canonical files for an incident.

## Supported contracts and freshness

This operation supports `AggregateVerifier` **0.3.0** at base/contracts `8c21f6d08a36b4059ae2bb8938f1e7e758a0e962` (v8.4.0.rc2). Both the live and replacement verifiers must report that version. The constructor has slow/fast block and intermediate intervals and a `ScheduleConfig`. Every non-hash constructor input is copied from the live verifier, including its anchor registry, factory, DelayedWETH, TEE/ZK verifier addresses, config hash, L2 chain ID, protocol versions, genesis block/timestamp, and block time. Any one, two, or all three hashes may change; all three must be nonzero and at least one must differ from the live verifier.

Re-review or retire this task before invocation if any of these change:

- AggregateVerifier ABI, getters, constructor, or supported contracts pin.
- `DisputeGameFactory.setImplementation(uint32,address)` signature or storage semantics.
- Ownership hierarchy: the factory owner must be the expected ProxyAdmin owner, a nested Safe owned by the Base multisig and Security Council. Review the live owners, thresholds, and nonces of all three Safes.
- Deployment settings, dependencies, compiler, or signing workflow.

The canonical Makefile reproduces the contracts pin's default AggregateVerifier profile: Solidity **0.8.15** (`v0.8.15+commit.e14f2714`), optimizer enabled with **999999** runs, `bytecode_hash=none`, EVM **cancun**, and no via IR. Dependency pins come from the root Makefile: forge-std `0844d7e1fc5e60d77b68e469bff60265f236c398`, solady `502cc1ea718e6fa73b380635ee0868b0740595f0`, and lib-keccak `3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9`. Do not override these settings. This task uses the shared Foundry project; `deps` replaces its libraries with the supported pin. Do not run another task's dependency installation concurrently. Archives copy the shared Foundry configuration and retain this Makefile's build settings.

## Hash provenance

For each supplied hash, independently reproduce the build and record its source revision, build image/toolchain, commands, and outputs in the invocation README or linked build evidence:

- TEE: reproducibly build the AWS Nitro enclave image, obtain its PCR0, and compute `cast keccak 0x<PCR0>`. The configured TEE image hash must equal that keccak256 value, not PCR0 itself.
- ZK range: reproduce the SP1 range ELF using `cargo prove build --docker` with the reviewed SP1 image, then derive the range verification key.
- ZK aggregate: reproduce the SP1 aggregation ELF the same way and derive its aggregation verification key. `just succinct vkeys --build` prints both vkeys for the reproducible prover build. Check the labels and avoid swapping them.

Confirm that the prover release and configured intervals are compatible with the supported verifier generation. An unchanged hash still needs provenance. Do not substitute sample hashes or rely solely on someone else's pasted output.

## Configure and deploy

Global `config/<network>.env` supplies `DISPUTE_GAME_FACTORY_PROXY`, `PROXY_ADMIN_OWNER`, `CB_MULTISIG`, `BASE_SECURITY_COUNCIL`, RPC, L1 chain ID, and Ledger account. The invocation `.env` contains exactly:

```dotenv
BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962
GAME_TYPE=<decimal-uint32>
CURRENT_AGGREGATE_VERIFIER=<expected-live-address>
AGGREGATE_VERIFIER_TEE_IMAGE_HASH=<nonzero-bytes32>
AGGREGATE_VERIFIER_ZK_RANGE_HASH=<nonzero-bytes32>
AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=<nonzero-bytes32>
```

Keep task-root `status.json` current as the invocation progresses, including signature counts and `last_updated`. Never put it under `config/<network>/`, which task-origin signing covers.

Do not add `RECORD_STATE_DIFF`; the signer injects it. No secrets belong in the config. Start the signer README with this concise template, replacing placeholders with reviewed values:

```markdown
Status: READY TO SIGN

# Rotate verifier hashes on <network>

Register <replacement-address> instead of <current-address> for game type <game-type>.
Change <which-hashes> to support <prover-release/reason>; preserve every other constructor input.

Hash provenance: <source-revision, reproducible-build-evidence, PCR0 and SP1 vkeys>.
Approvers: Base and Security Council through the ProxyAdmin owner Safe.
```

```sh
make TASK_NETWORK=<network> prepare
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> build
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<environment-secret> make TASK_NETWORK=<network> verify
```

`prepare` checks inputs without RPC. `deploy` broadcasts from the facilitator's Ledger EOA, not a Safe. It refuses an existing `addresses.json`; investigate a partial deployment before retrying. It writes `aggregateVerifier` and `aggregateVerifierConstructorArgs` under `config/<network>/addresses.json`, and broadcasts under task-scoped `records/`. Compare every replacement immutable against the expected live verifier, then verify source with the repository's custom Etherscan v2 verifier. `verify` fails without `VERIFIER_API_KEY`; supply it only from your environment and never commit it. Fill in the replacement address in the signer README and commit the deployment artifacts.

## Validate and collect nested approvals

```sh
make TASK_NETWORK=<network> validate
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

`validate` checks ownership, expected registration, versions, replacement code, all configured hashes, and every non-hash constructor input. It saves `config/<network>/prestate.json` for the separate post-execution check. Refresh this read-only baseline immediately before execution; it does not change the signed call. AggregateVerifier's factory game args must be empty.

The validations are `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Review their full generated state diff **before signing**, not just the calldata. The only factory storage write must move the target game type from the expected current verifier to the replacement. Other game types, game count, constructor/game args, and ownership must remain unchanged. Safe nonce and approval changes are expected. The scripts enforce factory write scope during both nested signing simulations and execution. Replace generated contract-name/summary placeholders with reviewed labels.

Task-origin validation applies only to mainnet because this flow uses the ProxyAdmin owner. For mainnet, collect the creator and both facilitator origin signatures:

```sh
make TASK_NETWORK=<network> sign-as-task-creator
make TASK_NETWORK=<network> sign-as-base-facilitator
make TASK_NETWORK=<network> sign-as-sc-facilitator
```

For other networks, generation invokes `standby-task.py skip-origin` for both validations. Do not skip origin validation on mainnet. Commit the invocation config, prestate, addresses, validations, and required origin signatures before asking signers to use:

```sh
make TASK_NETWORK=<network> sign-task
```

Choose this standby operation and the network in the signer UI. Base signers use `base-signer`; Security Council signers use `security-council-signer`. A canonical task without an invocation is not discoverable. Re-simulate and regenerate validations if the registration, constructor inputs, ownership hierarchy, Safe nonces, or proposed hashes change. Recollect signatures whenever the transaction hash changes.

## Execute and check

Collect each inner Safe's threshold of signatures in Safe owner-address order:

```sh
make TASK_NETWORK=<network> approve-cb SIGNATURES=<base-signatures>
make TASK_NETWORK=<network> approve-sc SIGNATURES=<security-council-signatures>
make TASK_NETWORK=<network> validate
make TASK_NETWORK=<network> execute
make TASK_NETWORK=<network> post-check
```

The outer Safe uses the nested approvals to execute one zero-value `setImplementation` call. Inline postchecks verify the target mapping, factory ownership, unchanged game count and args, versions, hashes, and immutable continuity. They reject every factory storage write outside the target mapping slot, including changes to unenumerable sibling game types.

`post-check` independently checks live state against the saved prestate. Run it immediately; unrelated new games after execution can change the count and require inspecting the execution transaction's pre/post state rather than treating a later count as an execution defect. Compare the actual execution state diff with the signed validation: the independent live check cannot reconstruct historical writes to arbitrary mapping keys. Keep the transaction diff and inline check results with the final artifacts. Games created before the switch retain their original implementation; this operation does not migrate them. Coordinate the prover rollout separately.

## Finalize and archive

Mark every invocation `Status: EXECUTED` with its transaction link or `Status: CANCELED` with a reason. Update the matching step and execution transaction in task-root `status.json` in the same change, then run `make check-task-status` from the repository root. Commit all final artifacts, including task-scoped records and signatures. Do not archive while any intended network invocation is pending, and do not merge the operational PR until the archive and invocation removals are committed.

Fetch main, then:

```sh
make TASK_NETWORK=<network> archive-task TASK_DATE=<YYYY-MM-DD>
```

Archival validates task-root `status.json` and rejects pending sibling networks, overwrites, invalid identifiers, and canonical drift from `origin/main`. It snapshots all finalized networks, global network configuration, task-root `status.json`, and task-scoped artifacts into `archive/evm/<YYYY-MM-DD>-update-verifier-hashes/`, removing only `config/`, `records/`, `signatures/`, and task-root `status.json` from standby. Canonical files stay byte-for-byte identical and contain no invocation data on main. Commit the dated archive and removals together. Never edit or execute a historical archive; the next invocation starts from this same standby directory.
