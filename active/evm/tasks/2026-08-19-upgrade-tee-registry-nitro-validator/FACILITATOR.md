# Facilitator Guide

Guide for deploying the hinted Nitro validator stack and upgrading the TEE registry. The active rollout is Sepolia; completed Zeronet artifacts remain in `config/zeronet/` and `records/`.

## 1. Install dependencies

```bash
cd active/evm/tasks/2026-08-19-upgrade-tee-registry-nitro-validator
make TASK_NETWORK=sepolia deps
```

## 2. Deploy contracts

Use the normal funded personal Ledger account:

```bash
make TASK_NETWORK=sepolia deploy-nitro-validator
VERIFIER_API_KEY=<key> make TASK_NETWORK=sepolia verify-nitro-validator
make TASK_NETWORK=sepolia deploy-tee-registry-impl
VERIFIER_API_KEY=<key> make TASK_NETWORK=sepolia verify-tee-registry-impl
```

This deploys and verifies `P384Verifier`, `CertManager`, `NitroValidator`, and a `TEEProverRegistry` implementation. It writes the addresses to `config/sepolia/addresses.json` and deployment records to `records/` under chain ID `11155111`.

Review and commit `config/sepolia/addresses.json` and the timestamped deployment records before generating validations. Do not modify the executed Zeronet artifacts.

## 3. Generate forward and rollback validations

```bash
make TASK_NETWORK=sepolia gen-validation-cb
make TASK_NETWORK=sepolia gen-validation-sc
make TASK_NETWORK=sepolia gen-validation-cb-rollback
make TASK_NETWORK=sepolia gen-validation-sc-rollback
```

For Sepolia, remove each generated `taskOriginConfig` and add this root field:

```json
"skipTaskOriginValidation": true
```

Commit the four validation files after reviewing their state diffs.

Record the current nonces for `PROXY_ADMIN_OWNER`, `CB_MULTISIG`, and `BASE_SECURITY_COUNCIL`. Do not allow unrelated transactions from those Safes during the cutover. Regenerate all validations if any nonce changes unexpectedly.

Expected forward state change: the TEE registry EIP-1967 implementation slot changes from `0xF9Ab55c35cE7Fb183A50E611B63558499130D849` to the implementation in `config/sepolia/addresses.json`.

Expected rollback state change: the same slot changes from the new implementation back to `0xF9Ab55c35cE7Fb183A50E611B63558499130D849`.

## 4. Collect signatures

Ask signers to run `make sign-task` from the repository root and select the Sepolia entry for this task. Collect signatures for all four validation files before cutover.

## 5. Prepare the offchain cutover

Confirm the migrated registrar uses signer `0x8074b32bD7d06C8f27596F3D6fbf867A36eA22a3` and retains `BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` to enable AWS CRL checks.

Keep the existing registrar and enclaves available for rollback. Stop the old registrar immediately before executing the onchain upgrade.

## 6. Approve and execute the upgrade

```bash
SIGNATURES=<base-signatures> make TASK_NETWORK=sepolia approve-cb
SIGNATURES=<security-council-signatures> make TASK_NETWORK=sepolia approve-sc
make TASK_NETWORK=sepolia execute
```

## 7. Start the migrated registrar

Start the migrated registrar after the proxy upgrade. Rotate one enclave first so its new ephemeral signer exercises certificate caching and hinted registration. Confirm the new signer is valid before rotating the remaining enclaves.

## 8. Roll back if required

If the migrated registrar path fails, use the rollback signatures collected before cutover:

```bash
SIGNATURES=<base-rollback-signatures> make TASK_NETWORK=sepolia approve-cb-rollback
SIGNATURES=<security-council-rollback-signatures> make TASK_NETWORK=sepolia approve-sc-rollback
make TASK_NETWORK=sepolia execute-rollback
```

Restart the legacy registrar after the rollback. Do not decommission the legacy Nitro verifier in this task.

## 9. Verify and archive

Verify the live proxy implementation, registry version, Nitro validator links, CertManager custody, registered signer state, and registrar health. Update the Sepolia signer README to `Status: [EXECUTED](<transaction-url>)`, commit execution records, and run `make archive-task` from the repository root only after the Sepolia rollout is complete.
