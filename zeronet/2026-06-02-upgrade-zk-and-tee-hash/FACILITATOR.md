# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd <network>/<date>-upgrade-zk-and-tee-hash
make deps
make deploy-aggregate-verifier VERIFIER_API_KEY=...
```

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- reuses the existing `ZkVerifier` from the current onchain AggregateVerifier
- writes `aggregateVerifier` to `addresses.json`

Expected `addresses.json` keys:

- `aggregateVerifier`

## Task origin signing

After setting up the task, generate cryptographic attestations to prove who created and facilitated the task. These signatures are stored in `<network>/signatures/<task-name>/`.

### Task creator

```bash
make sign-as-task-creator
```

### Base facilitator

```bash
make sign-as-base-facilitator
```

### Security Council facilitator

```bash
make sign-as-sc-facilitator
```

## Generate validation files

```bash
cd contract-deployments
git pull
cd <network>/<date>-upgrade-zk-and-tee-hash
make deps
make gen-validation-update-verifier-hashes-cb
make gen-validation-update-verifier-hashes-sc
```

This produces:

- `validations/base-signer.json`
- `validations/security-council-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd <network>/<date>-upgrade-zk-and-tee-hash
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
- all other AggregateVerifier immutables (`ZK_VERIFIER`, `TEE_VERIFIER`, `DELAYED_WETH`, `CONFIG_HASH`, etc.) match the previous AggregateVerifier
