# Facilitator Guide

Guide for facilitators managing this task.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-gas-and-elasticity-limit
make deps
make gen-validation-cb
make gen-validation-sc
make gen-validation-cb-rollback
make gen-validation-sc-rollback
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`
- `validations/base-signer-rollback.json`
- `validations/security-council-signer-rollback.json`

All four files should be made available in the signing UI so signers can sign
both the primary update and the rollback transaction for their respective Safe.

## Execute the upgrade

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-gas-and-elasticity-limit
make deps
```

### 2. Approve with CB Multisig signatures

Concatenate all CB Multisig signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Approve with Security Council signatures

Concatenate all Security Council signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-sc
```

### 4. Execute upgrade

```bash
make execute
```

## (**ONLY** if needed) Execute rollback

> [!IMPORTANT]
>
> THIS SHOULD ONLY BE PERFORMED IN THE EVENT THAT WE NEED TO ROLLBACK

### 1. Approve rollback with CB Multisig signatures

```bash
SIGNATURES=$SIGNATURES make approve-cb-rollback
```

### 2. Approve rollback with Security Council signatures

```bash
SIGNATURES=$SIGNATURES make approve-sc-rollback
```

### 3. Execute rollback

```bash
make execute-rollback
```
