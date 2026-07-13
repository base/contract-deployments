# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, deploy the replay contracts:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-may-aggregate
make deps
make deploy
```

`make deploy` writes these keys to `addresses.json`:

- `systemConfig`
- `sp1VerifierGateway`
- `zkVerifier`
- `aggregateVerifier`

## 1. Generate and execute the Nitro verifier ID update

Generate the Nitro validation file first:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-may-aggregate
make deps
make gen-validation-nitro
```

This produces `validations/nitro-base-signer.json`.

Collect Nitro owner signatures, concatenate them, and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make execute-nitro
```

## 2. Generate validation files for the replay batch

After the Nitro transaction executes, generate the replay batch validation files so the CB nonce is current:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-may-aggregate
make deps
make gen-validation-cb
make gen-validation-sc
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

## 3. Execute the replay batch

### 1. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-cb
```

### 2. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as `SIGNATURES`:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-sc
```

### 3. Execute the replay batch

```bash
make execute
```
