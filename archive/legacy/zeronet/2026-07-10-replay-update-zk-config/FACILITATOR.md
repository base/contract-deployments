# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, deploy the replay contracts:

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-update-zk-config
make deps
make deploy
```

`make deploy-zk-verifier` deploys the `ZkVerifier` used by this replay and writes `zkVerifier` to `addresses.json`.

`make deploy-aggregate-verifier` redeploys `AggregateVerifier` with the same live immutables, replacing only `ZK_VERIFIER`. It writes `aggregateVerifier` to `addresses.json`.

Expected `addresses.json` keys:

- `zkVerifier`
- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-07-10-replay-update-zk-config
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
cd zeronet/2026-07-10-replay-update-zk-config
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
