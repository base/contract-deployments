# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, deploy the replay contracts:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-09-replay-tee-registry-nitro-fixes
make deps
make deploy
```

`make deploy-nitro` deploys and configures a NitroEnclaveVerifier with the corrected verifier ID from `2026-04-17-fix-nitro-verifier`. It writes `nitroEnclaveVerifier` to `addresses.json`.

`make deploy-implementations` deploys a TEEProverRegistry implementation pointing at the new NitroEnclaveVerifier and an AggregateVerifier with the corrected TEE image hash from `2026-04-17-fix-tee-image-hash`. It writes `teeProverRegistryImpl` and `aggregateVerifier` to `addresses.json`.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-09-replay-tee-registry-nitro-fixes
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
cd zeronet/2026-07-09-replay-tee-registry-nitro-fixes
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-sc
```

### 4. Execute the replay batch

```bash
make execute
```
