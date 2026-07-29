# Facilitator Guide

Guide for facilitators managing this task.

## Task Origin Signing

After setting up the task, generate cryptographic attestations (sigstore bundles) to prove who created and facilitated the task. These signatures are stored in `<network>/signatures/<task-name>/`.

### Task creator (run after task setup):
```bash
make sign-as-task-creator
```

### Base facilitator:
```bash
make sign-as-base-facilitator
```

### Security Council facilitator:
```bash
make sign-as-sc-facilitator
```

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-gas-and-elasticity-limit
make deps
make gen-validation
make gen-validation-rollback
```

This produces:

- `validations/base-signer.json`
- `validations/base-signer-rollback.json`

## Execution

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-gas-and-elasticity-limit
make deps
```

### 2. Execute upgrade

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
