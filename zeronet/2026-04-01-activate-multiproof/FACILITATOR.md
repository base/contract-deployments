# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete all deploy steps:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
make deploy-cb-multicall
make deploy-nitro-verifier
make deploy-multiproof
```

`make deploy-cb-multicall` deploys the canonical `CBMulticall` helper used by `MultisigScript` signer-side simulations on zeronet.

The Nitro deploy step initializes `addresses.json`, and the main deploy step appends the remaining addresses used by the signed upgrade step.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
make gen-validation-multiproof-cb
make gen-validation-multiproof-sc
make gen-validation-setup-nitro
```

This produces:

- `validations/multiproof-cb-signer.json`
- `validations/multiproof-sc-signer.json`
- `validations/setup-nitro-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-01-activate-multiproof
make deps
```

### 2. Collect signatures for `TEE_PROVER_REGISTRY_OWNER`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES_TEE="[SIGNATURE1][SIGNATURE2]..."
```

### 3. Collect signatures for `CB_SIGNER_SAFE_ADDR`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-multiproof-cb
```

### 4. Collect signatures for `CB_SC_SAFE_ADDR`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-multiproof-sc
```

### 5. Execute the Nitro owner batch

Run this before the main multiproof activation batch. This executes the Nitro
owner batch directly using the collected signatures.

```bash
SIGNATURES=$SIGNATURES_TEE make execute-setup-nitro
```

### 6. Execute the multiproof activation batch

```bash
make execute-activate-multiproof
```


