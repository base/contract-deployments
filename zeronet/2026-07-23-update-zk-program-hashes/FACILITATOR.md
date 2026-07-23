# Facilitator Guide

## Deploy the AggregateVerifier

```bash
cd zeronet/2026-07-23-update-zk-program-hashes
make deps
make deploy VERIFIER_API_KEY=...
```

`make deploy` writes `aggregateVerifier` to `addresses.json`.

## Generate validation files

```bash
make gen-validation-cb
make gen-validation-sc
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

Do not generate validation files until `.env` and `addresses.json` are final.

## Execute the task

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-cb
SIGNATURES=$SIGNATURES make approve-sc
make execute
```
