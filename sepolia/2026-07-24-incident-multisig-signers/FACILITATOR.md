# Facilitator Guide

The same signer diff is applied to both Safes:

- Incident Multisig: `OWNER_SAFE` in [.env](./.env)
- Mock Security Council Safe: `SECURITY_COUNCIL_SAFE` in [.env](./.env)

## Generate validation files

```bash
cd contract-deployments/sepolia/2026-07-24-incident-multisig-signers
make deps
make gen-validation
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

Do not generate validation files until `.env` and [OwnerDiff.json](./OwnerDiff.json) are final.

## Execute the transactions

### Incident Multisig

Collect enough Incident Multisig signatures, concatenate them, and run:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute-incident
```

### Mock Security Council Safe

Collect enough mock Security Council Safe signatures, concatenate them, and run:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute-security-council
```

After execution, update [README.md](./README.md) status to `EXECUTED` with the transaction links and check in any generated execution records.
