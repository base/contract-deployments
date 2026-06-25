# Facilitator Guide

Guide for facilitators managing this task.

## Verify Hash Inputs

Before deploying or generating validation files, verify the configured hashes in `config/mainnet/.env`:

- `TEE_IMAGE_HASH`
- `ZK_RANGE_HASH`
- `ZK_AGGREGATE_HASH`

Confirm these match the final Mainnet Beryl values before deployment; the scripts also reject zero hashes.

## Deployment Prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd active/evm
make deps
TASK_ID=2026-06-18-beryl-2 make deploy-aggregate-verifier VERIFIER_API_KEY=...
```

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- reuses the existing `TEE_VERIFIER` and `ZK_VERIFIER` from the current onchain `AggregateVerifier`
- writes `aggregateVerifier` to `tasks/2026-06-18-beryl-2/addresses.json`

Expected `addresses.json` keys:

- `aggregateVerifier`

## Generate Validation Files

```bash
cd contract-deployments
git pull
cd active/evm
make deps
TASK_ID=2026-06-18-beryl-2 make gen-validation-update-verifier-hashes-cb
TASK_ID=2026-06-18-beryl-2 make gen-validation-update-verifier-hashes-sc
```

This produces:

- `tasks/2026-06-18-beryl-2/config/mainnet/validations/coinbase-signer.json`
- `tasks/2026-06-18-beryl-2/config/mainnet/validations/security-council-signer.json`

Do not generate validation files until `.env` and `addresses.json` are final.

Mainnet validation files must not contain `skipTaskOriginValidation`.

## Collect Task Origin Signatures

After `config/mainnet/.env`, `addresses.json`, and validation files are final, collect task origin signatures. Follow `TASK_ORIGIN.md`.

Mainnet signatures are stored in:

- `tasks/2026-06-18-beryl-2/config/mainnet/signatures/creator-signature.json`
- `tasks/2026-06-18-beryl-2/config/mainnet/signatures/base-facilitator-signature.json`
- `tasks/2026-06-18-beryl-2/config/mainnet/signatures/base-sc-facilitator-signature.json`

The sepolia and zeronet configs are copied from mainnet for signer-tool layout demonstration only.

## Execute The Transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd active/evm
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES TASK_ID=2026-06-18-beryl-2 make approve-update-verifier-hashes-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES TASK_ID=2026-06-18-beryl-2 make approve-update-verifier-hashes-sc
```

### 4. Execute upgrade batch

```bash
TASK_ID=2026-06-18-beryl-2 make execute-update-verifier-hashes
```
