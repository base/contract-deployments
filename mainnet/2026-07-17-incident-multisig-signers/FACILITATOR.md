# Facilitator Guide

Guide for facilitators managing this task.

The signer diff is applied to the Mainnet Incident Multisig: `OWNER_SAFE` in [.env](./.env).

## Generate validation file

```bash
cd contract-deployments
git pull
cd mainnet/2026-07-17-incident-multisig-signers
make deps
make gen-validation
```

This produces:

- `validations/base-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd mainnet/2026-07-17-incident-multisig-signers
make deps
```

### 2. Execute the Incident Multisig update

Collect enough Incident Multisig signatures, concatenate them, and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute
```

After execution, update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any generated execution records.
