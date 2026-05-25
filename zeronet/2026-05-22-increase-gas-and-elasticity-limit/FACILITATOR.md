# Facilitator Guide

Guide for facilitators managing this task.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-gas-and-elasticity-limit
make deps
make gen-validation
make gen-validation-rollback
```

This produces:

- `validations/base-signer.json`
- `validations/base-signer-rollback.json`

Both files should be made available in the signing UI so signers can sign the
primary update and the rollback transaction.

## Execution

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-gas-and-elasticity-limit
make deps
```

### 2. Execute upgrade

Concatenate the primary signatures collected from signers and export as the
`SIGNATURES` environment variable:

```bash
SIGNATURES=AAABBBCCC make execute
```

### 3. (**ONLY** if needed) Execute upgrade rollback

> [!IMPORTANT]
>
> THIS SHOULD ONLY BE PERFORMED IN THE EVENT THAT WE NEED TO ROLLBACK

```bash
SIGNATURES=AAABBBCCC make execute-rollback
```
