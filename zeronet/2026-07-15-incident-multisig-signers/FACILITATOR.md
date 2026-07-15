# Facilitator Guide

Guide for facilitators managing this task.

## Before generating validations

Replace the placeholder addresses in [OwnerDiff.json](./OwnerDiff.json) with the final signer addresses.

The same signer diff is applied to both Safes:

- Incident Multisig: `OWNER_SAFE` in [.env](./.env)
- Mock Security Council Safe: `SECURITY_COUNCIL_SAFE` in [.env](./.env)

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-15-incident-multisig-signers
make deps
make gen-validation
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

## Execute the transactions

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-15-incident-multisig-signers
make deps
```

### 2. Execute the Incident Multisig update

Collect enough Incident Multisig signatures, concatenate them, and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute-incident
```

### 3. Execute the mock Security Council Safe update

Collect enough mock Security Council Safe signatures, concatenate them, and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute-security-council
```

After execution, update [README.md](./README.md) status to `EXECUTED` with the transaction links and check in any generated execution records.
