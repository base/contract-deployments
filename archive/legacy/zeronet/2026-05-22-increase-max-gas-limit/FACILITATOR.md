# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-max-gas-limit
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
cd zeronet/2026-05-22-increase-max-gas-limit
make deps
make gen-validation-cb
make gen-validation-sc
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-22-increase-max-gas-limit
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

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

Post-checks enforced by script:

- `SystemConfig(impl).version()` equals `"3.13.2+max-gas-limit-2000M"`
- `SystemConfig(impl).maximumGasLimit()` equals `2,000,000,000`
- SystemConfig proxy implementation slot points to the new implementation
