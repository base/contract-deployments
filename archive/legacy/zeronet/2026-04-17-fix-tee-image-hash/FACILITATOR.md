# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-tee-image-hash
make deps
make deploy-aggregate-verifier
```

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding only `TEE_IMAGE_HASH` with the corrected value
- writes `addresses.json`

Expected `addresses.json` key:

- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-tee-image-hash
make deps
make gen-validation-fix-cb
make gen-validation-fix-sc
```

This produces:

- `validations/fix-tee-image-hash-cb-signer.json`
- `validations/fix-tee-image-hash-sc-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-tee-image-hash
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-fix-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-fix-sc
```

### 4. Execute upgrade batch

```bash
make execute-fix
```

Post-checks enforced by script:

- `DisputeGameFactory.gameImpls(621)` equals the newly deployed `aggregateVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` equals `TEE_IMAGE_HASH`
