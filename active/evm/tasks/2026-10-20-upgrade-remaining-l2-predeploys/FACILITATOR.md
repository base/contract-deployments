# Remaining L2 predeploy upgrades

This task upgrades the ERC721 factory, OperatorFeeVault, SchemaRegistry and EAS through four separate L1 deposits to the L2 ProxyAdmin. The L1 ProxyAdmin owner's L2 alias must own the L2 ProxyAdmin. The script supports only Sepolia L1 and Base Sepolia L2. Every Make command requires command-line `TASK_NETWORK`.

The messenger, standard bridge, ERC721 bridge and ERC20 factory cannot safely use v8.4.0 directly. Their initializer version is already 2. The new implementations require configuration in empty or relocated slots but only expose version-1 initializers. They are excluded pending a separate migration. BaseTime is excluded because Denim must install its canonical implementation while its proxy implementation slot is zero.

Ordering is independent of Denim activation. The four included implementations do not read BaseTime or new L1Block fields and Denim's network transition does not upgrade them. There is no timestamp guard. The operator vault keeps its recipient, minimum and withdrawal network through upgradeAndCall. EAS changes its delegated-signature domain version to 1.3.0, invalidating outstanding signatures for 1.2.0.

Run from this task directory. Replace `<network>` with the configured network. The invocation currently accepts only `sepolia`.

## Prepare and simulate

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> build
make TASK_NETWORK=<network> simulate-l2
```

Review `config/<network>/.env` against fresh live reads. The fork tests deploy implementations locally, replay the deposits as the aliased owner, check configuration and preserve schema and attestation records. They also verify the four excluded migrations revert. The L1 test exercises MultisigScript's signer simulation and the actual L2 fork post-check with local implementations persisted across forks. No test broadcasts.

The repository's internal L1 RPC may be unavailable. A public Sepolia RPC can be selected explicitly with `L1_RPC_URL=<url>` on any command. `config/<network>/.env` selects the public L2 RPC.

## Deploy implementations

```bash
make TASK_NETWORK=<network> deploy
```

Only the facilitator runs this step with an L2-funded deployment account. The task-local Foundry config matches base/contracts compiler settings: exact Solidity 0.8.15 for the factory with 5000 optimizer runs; 0.8.25 for the operator vault and 0.8.19 for attestations with 999999 runs. All use Cancun and no bytecode hash. Compiler restrictions also build the factory's token bytecode with 5000 runs.

Each deployment checks version() and writes to `config/<network>/addresses.json`. Commit that file and task-scoped `records/`. Never substitute the local fork test's deployment addresses.

## Generate validations

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

The implementation-file guard must pass before validation, approval or execution. The signing simulation checks the L1 deposits and replays the exact four L2 calls. Each deposit buys 200000 L2 gas. The heaviest measured call used about 69000 gas before transaction intrinsic gas, leaving margin.

Review `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Replace generated descriptive placeholders. For this testnet invocation remove any generated `taskOriginConfig` and set `skipTaskOriginValidation` to `true`. No task-origin signatures are required. Commit validations before asking signers to sign.

Update task-root `status.json` as authoring, validation and signing progress. Keep signature counts current. Share `config/<network>/README.md` with signers.

## Approve and execute

```bash
SIGNATURES=<base-signatures> make TASK_NETWORK=<network> approve-cb
SIGNATURES=<security-council-signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

Confirm each deposit succeeds on L2, not just that the L1 transaction succeeds. Check implementation addresses, versions and configuration against the validations. Commit task-scoped records. Finalize the signer README and task-root status together, then run `make check-task-status` from the repository root. Do not archive while an intended invocation remains pending.
