# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

```bash
cd contract-deployments
git pull
cd sepolia/2026-07-21-upgrade-plonk-and-verifier-hashes
make deps
make deploy VERIFIER_API_KEY=...
```

`make deploy` writes `aggregateVerifier` to `addresses.json`.

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-07-21-upgrade-plonk-and-verifier-hashes
make deps
make gen-validation-cb
make gen-validation-sc
```

This produces:

- `validations/coinbase-signer.json`
- `validations/security-council-signer.json`

Do not generate validation files until `.env` and `addresses.json` are final.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-07-21-upgrade-plonk-and-verifier-hashes
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-sc
```

### 4. Execute

```bash
make execute
```
