# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete both deploy steps:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
make deploy-nitro-enclave-verifier
make deploy
```

This produces a single `addresses.json`. The Nitro deploy step initializes it, and the main deploy step appends the remaining addresses used by the signed upgrade step.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
make gen-validation-upgrade
```

This produces:

- `validations/base-signer.json`
- `validations/base-sc-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
```

### 2. Collect signatures for `CB_SIGNER_SAFE_ADDR`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Collect signatures for `CB_SC_SAFE_ADDR`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-sc
```

### 4. Execute

```bash
make execute
```
