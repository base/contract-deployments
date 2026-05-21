# Facilitator Guide

Guide for facilitators managing this task.

## Generate validation file

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-21-update-nitro-verifier-id
make deps
make gen-validation
```

This produces `validations/base-signer.json`, which signers should use in the signing UI.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-21-update-nitro-verifier-id
make deps
```

### 2. Collect signatures from all participating signers

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

### 3. Execute

```bash
SIGNATURES=$SIGNATURES make execute
```
