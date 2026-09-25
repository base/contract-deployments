# Facilitator Guide

## Generate the validation file

```bash
cd zeronet/2026-07-15-fix-nitro-verifier-id
make deps
make gen-validation
```

This creates `validations/base-signer.json`.

The script requires the live RISC Zero verifier ID to equal `CURRENT_NITRO_ZK_VERIFIER_ID` before it creates the approval payload.

## Execute

Collect the required signatures, then run:

```bash
SIGNATURES="[SIGNATURE1][SIGNATURE2]..." make execute
```
