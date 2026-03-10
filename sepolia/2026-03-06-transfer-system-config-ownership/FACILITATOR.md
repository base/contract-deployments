# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

## Generate validation file

```bash
cd contract-deployments
git pull
cd sepolia/2026-03-06-transfer-system-config-ownership
make deps
make gen-validation
```

This produces `validations/coinbase-signer.json`, which signers should use in the signing UI.

## Execute the transaction

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2026-03-06-transfer-system-config-ownership
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
