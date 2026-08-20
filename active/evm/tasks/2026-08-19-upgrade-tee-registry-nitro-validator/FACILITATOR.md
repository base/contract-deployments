# Facilitator Guide

Guide for deploying the hinted Nitro validator stack and upgrading the TEE registry on a selected network.

Before running anything, replace every literal `NETWORK_NAME` below with the selected config directory, for example `sepolia`. The Makefile has no default and rejects an inherited or exported `TASK_NETWORK`; every invocation must visibly use `make TASK_NETWORK=<network> <target>`.

## 1. Install dependencies

```bash
cd active/evm/tasks/2026-08-19-upgrade-tee-registry-nitro-validator
make TASK_NETWORK=NETWORK_NAME deps
```

## 2. Deploy contracts

Use the normal funded personal Ledger account:

```bash
make TASK_NETWORK=NETWORK_NAME deploy-nitro-validator
VERIFIER_API_KEY=<key> make TASK_NETWORK=NETWORK_NAME verify-nitro-validator
make TASK_NETWORK=NETWORK_NAME deploy-tee-registry-impl
VERIFIER_API_KEY=<key> make TASK_NETWORK=NETWORK_NAME verify-tee-registry-impl
```

This deploys and verifies `P384Verifier`, `CertManager`, `NitroValidator`, and a `TEEProverRegistry` implementation. It writes the addresses to `config/NETWORK_NAME/addresses.json` and chain-keyed deployment records under `records/`.

Review and commit the selected network's addresses and timestamped deployment records before generating validations. Do not modify artifacts from completed network rollouts.

## 3. Generate forward and rollback validations

```bash
make TASK_NETWORK=NETWORK_NAME gen-validation-cb
make TASK_NETWORK=NETWORK_NAME gen-validation-sc
make TASK_NETWORK=NETWORK_NAME gen-validation-cb-rollback
make TASK_NETWORK=NETWORK_NAME gen-validation-sc-rollback
```

For a non-mainnet rollout, remove each generated `taskOriginConfig` and add this root field to all four validation files:

```json
"skipTaskOriginValidation": true
```

For a mainnet rollout through the proxy admin owner, retain task-origin validation and collect the required task-origin signatures.

Commit the four validation files after reviewing their state diffs.

Record the current nonces for `PROXY_ADMIN_OWNER`, `CB_MULTISIG`, and `BASE_SECURITY_COUNCIL`. Do not allow unrelated transactions from those Safes during the cutover. Regenerate all validations if any nonce changes unexpectedly.

Expected forward state change: the TEE registry EIP-1967 implementation slot changes from `OLD_TEE_PROVER_REGISTRY_IMPL` in `config/NETWORK_NAME/.env` to the implementation in `config/NETWORK_NAME/addresses.json`.

Expected rollback state change: the same slot changes from the new implementation back to `OLD_TEE_PROVER_REGISTRY_IMPL`.

## 4. Collect signatures

Ask signers to run `make sign-task` from the repository root and select the chosen network entry for this task. Collect signatures for all four validation files before cutover.

## 5. Prepare the offchain cutover

Confirm the migrated registrar uses the signer configured as `CERT_MANAGER_REVOKER` in `config/NETWORK_NAME/.env` and retains `BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` to enable AWS CRL checks.

Keep the existing registrar and enclaves available for rollback. Stop the old registrar immediately before executing the onchain upgrade.

## 6. Approve and execute the upgrade

```bash
SIGNATURES=<base-signatures> make TASK_NETWORK=NETWORK_NAME approve-cb
SIGNATURES=<security-council-signatures> make TASK_NETWORK=NETWORK_NAME approve-sc
make TASK_NETWORK=NETWORK_NAME execute
```

## 7. Start the migrated registrar

Start the migrated registrar after the proxy upgrade. Rotate one enclave first so its new ephemeral signer exercises certificate caching and hinted registration. Confirm the new signer is valid before rotating the remaining enclaves.

## 8. Roll back if required

If the migrated registrar path fails, use the rollback signatures collected before cutover:

```bash
SIGNATURES=<base-rollback-signatures> make TASK_NETWORK=NETWORK_NAME approve-cb-rollback
SIGNATURES=<security-council-rollback-signatures> make TASK_NETWORK=NETWORK_NAME approve-sc-rollback
make TASK_NETWORK=NETWORK_NAME execute-rollback
```

Restart the legacy registrar after the rollback. Do not decommission the legacy Nitro verifier in this task.

## 9. Verify and archive

Verify the live proxy implementation, registry version, Nitro validator links, CertManager custody, registered signer state, and registrar health. Update `config/NETWORK_NAME/README.md` to `Status: [EXECUTED](<transaction-url>)` and commit execution records. Run `make archive-task` from the repository root only after every currently intended network rollout is complete.
