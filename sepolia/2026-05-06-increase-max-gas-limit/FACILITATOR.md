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

## Deployment prerequisites

Before collecting signatures, deploy the patched SystemConfig implementation:

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-max-gas-limit
make deps
make deploy
```

`make deploy` runs `DeploySystemConfigScript`:

- deploys a new `SystemConfig` implementation with `MAX_GAS_LIMIT = 2,000,000,000` and version `3.13.2+max-gas-limit-2000M`
- writes `systemConfig` to `addresses.json`

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-max-gas-limit
make deps
make gen-validation-base
make gen-validation-op
```

This produces:

- `validations/base-signer.json`
- `validations/op-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-max-gas-limit
make deps
```

### 2. Collect signatures for `BASE_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-base
```

### 3. Collect signatures for `OP_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-op
```

### 4. Execute upgrade

```bash
make execute
```

Post-checks enforced by script:

- `SystemConfig(impl).version()` equals `"3.13.2+max-gas-limit-2000M"`
- `SystemConfig(impl).maximumGasLimit()` equals `2,000,000,000`
- SystemConfig proxy implementation slot points to the new implementation
