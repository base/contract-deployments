# Pause task integration and facilitation

## Include the shared signing recipe

For an active task at `active/evm/tasks/<task-id>/`, use this Makefile structure. The shared include requires `TASK_NETWORK` on every command line, even when the task has only one network. Include it before loading network configuration so an exported environment value cannot select the network.

```make
include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk
include $(REPO_ROOT)/active/evm/script/common/superchain/PauseSigning.mk

PROJECT_DIR := $(abspath ../..)
include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

RPC_URL := $(L1_RPC_URL)
SCRIPT_NAME := script/common/superchain/PauseSuperchainConfig.s.sol:PauseSuperchainConfig
export INCIDENT_MULTISIG SYSTEM_CONFIG

.PHONY: execute-pause
execute-pause:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
```

The loaded configuration must define `INCIDENT_MULTISIG`, `SYSTEM_CONFIG`, and `LEDGER_ACCOUNT`. Put task-specific addresses in `config/<network>/.env`. The repository's `config/<network>.env` supplies `L1_RPC_URL` and a default Ledger account; use the task's approved RPC endpoint and signer account. Configure the shared Forge project's contract dependencies as required by the task. The include adds only `deps-pause` and `sign-pause`; it does not add execution or approval targets.

`deps-pause` sets `GOBIN` for its install command to the mise Go `GOROOT/bin` and installs `github.com/base/eip712sign@v0.0.11` there. `sign-pause` depends on that install and resolves the same `GOROOT` at runtime. Ordinary `go install` would otherwise use `GOBIN` or `GOPATH/bin`. The repository's existing `install-eip712sign` target and other tasks are unchanged.

Put signer instructions in `config/<network>/README.md` with `Status: READY TO SIGN`. List EVERY intended network and state that each signer must sign 20 transactions on EACH network. Link to the [shared signer guide](README.md), and give explicit `make TASK_NETWORK=<network> sign-pause` commands and the `config/<network>/signatures-pause.txt` handoff path. Do not put signatures in the shared code directory.

## Task-root facilitator guide

Keep the task's own `FACILITATOR.md` authoritative and network-agnostic. List the intended networks and use `TASK_NETWORK=<network>` and `config/<network>/` throughout. Include the following procedure, with task-specific Safe owners and execution checks.

1. Verify the Incident Safe, SystemConfig, chain ID, Ledger accounts, and task revision for each network. Agree on a signing window when the Incident Safe's nonce will not change. Each signer needs a separate local checkout or worktree because output files are local to the signer, task, and network.
2. Ask each signer to run `make TASK_NETWORK=<network> sign-pause` for EACH network. Collect the contents of `config/<network>/signatures-pause.txt`, not terminal output. Check that every batch contains 20 entries with the same signer and sequential nonces, and that all signers used the intended starting nonce for that network.
3. If signing stops after three attempts, have the signer fix the Ledger connection and rerun the same command with the same account. Successful signatures remain in `config/<network>/.pause-signing`. If the signing context has changed, explicitly approve abandoning the old batch and confirm the new context with the signer before any restart. Follow the [context-change restart steps](README.md#restart-after-a-context-change): confirm no signing process is running, preserve `config/<network>/.pause-signing` at an unused `config/<network>/.pause-signing-preserved-<batch-id>` path, verify the preserved files, remove only a stale `config/<network>/.pause-signing.lock`, then rerun with the approved configuration and account. Keep the preserved batch until its disposal is approved. Never mix batches from different starting nonces or networks.
4. Store each network's collected signatures according to the task's approved procedure. Before execution, check the current Safe nonce and pause state. For the Makefile example above, the task's execution command is `make TASK_NETWORK=<network> SIGNATURES=<safe-signatures> LEDGER_ACCOUNT=<executor-account> execute-pause`. Select the signatures for the current nonce and aggregate them into the Safe's required format and signer order. Do not pass the entire comma-separated batch file as `SIGNATURES`.
5. Verify the onchain pause state and commit final task artifacts under the selected network's configuration. Keep the task active until all intended network rollouts are executed or canceled.

These pause signatures come directly from `eip712sign`, so this signing path has no task-signing-tool validation JSON or separate approval transaction. If the task also has operations that use validation files or nested-Safe approvals, document their generation and approval commands in the task-root guide, use simple validation names such as `base-signer.json`, and scope their paths under `config/<network>/`. Generate those files during task finalization, not while integrating this shared recipe.

## Mock-only regression tests

From the repository root:

```sh
python3 -B -m unittest discover -s active/evm/script/common/superchain/tests -p 'test_pause_signing.py' -v
```

The tests run the public Makefile target in temporary task fixtures with fake mise, Go, cast, and eip712sign. They do not use a Ledger, live RPC, or transaction execution.
