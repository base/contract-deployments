# Facilitator Guide

Guide for facilitators managing this task.

## Verify Hash Inputs

Before deploying or generating validation files, verify the configured hashes in `.env`:

- `TEE_IMAGE_HASH`
- `ZK_RANGE_HASH`
- `ZK_AGGREGATE_HASH`

The scripts reject zero hashes to prevent accidental deployment with placeholders.

## Deployment Prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-06-13-upgrade-zk-and-tee-hash
make deps
make deploy-aggregate-verifier VERIFIER_API_KEY=...
```

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- reuses the existing `TEE_VERIFIER` and `ZK_VERIFIER` from the current onchain `AggregateVerifier`
- writes `aggregateVerifier` to `addresses.json`

Expected `addresses.json` keys:

- `aggregateVerifier`

## Generate Validation Files

```bash
cd contract-deployments
git pull
cd zeronet/2026-06-13-upgrade-zk-and-tee-hash
make deps
make gen-validation-update-verifier-hashes-cb
make gen-validation-update-verifier-hashes-sc
```

This produces:

- `validations/coinbase-signer.json`
- `validations/security-council-signer.json`

Do not generate validation files until `.env` and `addresses.json` are final.

## Execute The Transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-06-13-upgrade-zk-and-tee-hash
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-verifier-hashes-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-verifier-hashes-sc
```

### 4. Execute upgrade batch

```bash
make execute-update-verifier-hashes
```

Post-checks enforced by script:

- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` equals the configured `TEE_IMAGE_HASH`
- `aggregateVerifier.ZK_RANGE_HASH()` equals the configured `ZK_RANGE_HASH`
- `aggregateVerifier.ZK_AGGREGATE_HASH()` equals the configured `ZK_AGGREGATE_HASH`
- all other `AggregateVerifier` immutables (`ZK_VERIFIER`, `TEE_VERIFIER`, `DELAYED_WETH`, `CONFIG_HASH`, etc.) match the previous `AggregateVerifier`
