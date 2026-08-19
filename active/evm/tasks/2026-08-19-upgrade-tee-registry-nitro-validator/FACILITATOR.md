# Facilitator Guide

Guide for deploying the hinted Nitro validator stack and upgrading the Zeronet TEE registry.

## 1. Install dependencies

```bash
cd active/evm/tasks/2026-08-19-upgrade-tee-registry-nitro-validator
make deps
```

## 2. Deploy contracts

Use the normal funded personal Ledger account:

```bash
make deploy-nitro-validator
VERIFIER_API_KEY=<key> make verify-nitro-validator
make deploy-tee-registry-impl
VERIFIER_API_KEY=<key> make verify-tee-registry-impl
```

This deploys and verifies `P384Verifier`, `CertManager`, `NitroValidator`, and a `TEEProverRegistry` implementation. It writes the addresses to `addresses.json` and deployment records to `records/`.

Review and commit `addresses.json` and the timestamped deployment records before generating validations.

## 3. Generate forward and rollback validations

```bash
make gen-validation-cb
make gen-validation-sc
make gen-validation-cb-rollback
make gen-validation-sc-rollback
```

For Zeronet, remove each generated `taskOriginConfig` and add this root field:

```json
"skipTaskOriginValidation": true
```

Commit the four validation files after reviewing their state diffs.

Record the current nonces for `PROXY_ADMIN_OWNER`, `CB_MULTISIG`, and `BASE_SECURITY_COUNCIL`. Do not allow unrelated transactions from those Safes during the cutover. Regenerate all validations if any nonce changes unexpectedly.

Expected forward state change: the TEE registry EIP-1967 implementation slot changes from `0x98ff839d2671bbaf6394bf03a496ea634f8a39c8` to the implementation in `addresses.json`.

Expected rollback state change: the same slot changes from the new implementation back to `0x98ff839d2671bbaf6394bf03a496ea634f8a39c8`.

## 4. Collect signatures

Ask signers to run `make sign-task` from the repository root and select this task. Collect signatures for all four validation files before cutover.

## 5. Prepare the offchain cutover

Confirm the migrated registrar uses signer `0x5F109182a097c40Cc936742be4B55c1A08aC4dd9` and retains `BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` to enable AWS CRL checks.

Keep the existing registrar and enclaves available for rollback. Stop the old registrar immediately before executing the onchain upgrade.

## 6. Approve and execute the upgrade

```bash
SIGNATURES=<base-signatures> make approve-cb
SIGNATURES=<security-council-signatures> make approve-sc
make execute
```

## 7. Start the migrated registrar

Start the migrated registrar after the proxy upgrade. Rotate one enclave first so its new ephemeral signer exercises certificate caching and hinted registration. Confirm the new signer is valid before rotating the remaining enclaves.

## 8. Roll back if required

If the migrated registrar path fails, use the rollback signatures collected before cutover:

```bash
SIGNATURES=<base-rollback-signatures> make approve-cb-rollback
SIGNATURES=<security-council-rollback-signatures> make approve-sc-rollback
make execute-rollback
```

Restart the legacy registrar after the rollback. Do not decommission the legacy Nitro verifier in this task.

## 9. Verify and archive

Verify the live proxy implementation, registry version, Nitro validator links, CertManager custody, registered signer state, and registrar health. Update the signer README to `Status: [EXECUTED](<transaction-url>)`, commit execution records, and run `make archive-task` from the repository root before merging the PR.
