# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, deploy the replay contract:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-june-aggregate
make deps
make deploy
```

`make deploy` writes `aggregateVerifier` to `addresses.json`.

Expected `addresses.json` keys:

- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-june-aggregate
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
cd zeronet/2026-07-10-replay-june-aggregate
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-sc
```

### 4. Execute the replay batch

```bash
make execute
```
