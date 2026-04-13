# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete all deploy steps:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-07-upgrade-tee-registry-nitro
make deps
make deploy-and-setup
```

`make deploy-and-setup` performs the EOA-authorized phase:

- runs `DeployAndSetupNitro`:
  - deploys new `NitroEnclaveVerifier`
  - sets Nitro routes and proof submitter
  - transfers Nitro ownership to `TEE_PROVER_REGISTRY_OWNER`
  - writes initial `addresses.json`
- runs `DeployTeeProverRegistryImpl`:
  - deploys new `TEEProverRegistry` implementation
  - appends `teeProverRegistryImpl` to `addresses.json`
- runs `DeployAggregateVerifier`:
  - redeploys `AggregateVerifier` with same immutables as existing one
  - appends `aggregateVerifier` to `addresses.json`

Expected `addresses.json` keys:

- `nitroEnclaveVerifier`
- `teeProverRegistryImpl`
- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-07-upgrade-tee-registry-nitro
make deps
make gen-validation-upgrade-tee-cb
make gen-validation-upgrade-tee-sc
```

This produces:

- `validations/upgrade-tee-registry-cb-signer.json`
- `validations/upgrade-tee-registry-sc-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-07-upgrade-tee-registry-nitro
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-upgrade-tee-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-upgrade-tee-sc
```

### 4. Execute upgrade batch

```bash
make execute-upgrade-tee
```

Post-checks enforced by script:

- `TEE_PROVER_REGISTRY_PROXY` implementation equals `teeProverRegistryImpl`
- `TEEProverRegistry(proxy).NITRO_VERIFIER()` equals `nitroEnclaveVerifier`
- `DisputeGameFactory.gameImpls(gameType)` equals `aggregateVerifier`
