# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-23-update-zk-config
make deps
make deploy-zk-verifier
make deploy-aggregate-verifier
```

`make deploy-zk-verifier` runs `DeployZkVerifier`:

- deploys the `ZkVerifier` used by this task
- writes `zkVerifier` to `addresses.json`

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `ZK_VERIFIER` and `ZK_RANGE_HASH`
- writes `aggregateVerifier` to `addresses.json`

Expected `addresses.json` keys:

- `zkVerifier`
- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-23-update-zk-config
make deps
make gen-validation-update-zk-config-cb
make gen-validation-update-zk-config-sc
```

This produces:

- `validations/update-zk-config-cb-signer.json`
- `validations/update-zk-config-sc-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-23-update-zk-config
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-zk-config-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-zk-config-sc
```

### 4. Execute upgrade batch

```bash
make execute-update-zk-config
```

Post-checks enforced by script:

- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `zkVerifier.SP1_VERIFIER()` equals the configured `SP1_VERIFIER`
- `aggregateVerifier.ZK_VERIFIER()` equals the newly deployed `zkVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` matches the live `AggregateVerifier`
- `aggregateVerifier.ZK_RANGE_HASH()` equals the configured `ZK_RANGE_HASH`
- `aggregateVerifier.ZK_AGGREGATE_HASH()` matches the live `AggregateVerifier`
