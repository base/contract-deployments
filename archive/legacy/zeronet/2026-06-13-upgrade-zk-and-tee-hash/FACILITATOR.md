# Facilitator Guide

Guide for facilitators managing this task.

## Verify Inputs

Before deploying or generating validation files, verify the configured hashes in `.env`:

- `TEE_IMAGE_HASH`
- `ZK_RANGE_HASH`
- `ZK_AGGREGATE_HASH`

The scripts reject zero hashes to prevent accidental deployment with placeholders.

Also verify the configured anchor reset inputs:

- `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `STARTING_ANCHOR_ROOT`

## Deployment Prerequisites

Before collecting signatures, ensure both EOA-authorized deployments are complete. `aggregateVerifier` is already present in `addresses.json`; rerun its deployment only if that address needs to be replaced.

```bash
cd contract-deployments
git pull
cd zeronet/2026-06-13-upgrade-zk-and-tee-hash
make deps
# Only rerun this if `aggregateVerifier` needs to be replaced:
make deploy-aggregate-verifier VERIFIER_API_KEY=...
make deploy-anchor-state-registry VERIFIER_API_KEY=...
```

`make deps` applies `patch/asr-reset-anchor-game.patch`, which patches `lib/contracts/src/L1/proofs/AnchorStateRegistry.sol` to:

- bump `ReinitializableBase(2)` to `ReinitializableBase(6)`, matching the live proxy's `initVersion() + 1`
- clear `anchorGame` inside `initialize()`

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- reuses the existing `TEE_VERIFIER` and `ZK_VERIFIER` from the current onchain `AggregateVerifier`
- writes `aggregateVerifier` to `addresses.json`

`make deploy-anchor-state-registry` runs `DeployAnchorStateRegistry`:

- snapshots `disputeGameFinalityDelaySeconds` and `initVersion` from the live `AnchorStateRegistry` proxy
- deploys a new `AnchorStateRegistry` implementation preserving the finality delay
- asserts `nextImpl.initVersion() == currentInitVersion + 1`
- writes `anchorStateRegistryImpl` to `addresses.json`

Expected `addresses.json` keys:

- `aggregateVerifier`
- `anchorStateRegistryImpl`

Do not generate validation files until `.env` and `addresses.json` are final.

## Pre-Sign Anchor Check

`STARTING_ANCHOR_ROOT` and `STARTING_ANCHOR_L2_BLOCK_NUMBER` are chain-critical. Before collecting signatures, verify both values against the zeronet op-node RPC.

### 1. Validate Finality

Confirm `STARTING_ANCHOR_L2_BLOCK_NUMBER` from `.env` is at or below the finalized L2 block:

```bash
cast rpc optimism_syncStatus --rpc-url https://base-zeronet-reth-rpc-donotuse.cbhq.net:7545 \
  | jq -r '.finalized_l2.number'
```

Expected result:

- `finalized_l2.number >= STARTING_ANCHOR_L2_BLOCK_NUMBER`

### 2. Validate Output Root

Use `optimism_outputAtBlock` with the same block and compare to `STARTING_ANCHOR_ROOT` from `.env`:

```bash
source .env
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock $(cast 2h $BLOCK) \
  --rpc-url https://base-zeronet-reth-rpc-donotuse.cbhq.net:7545 | jq -r '.outputRoot')
echo $OUTPUT_ROOT
echo $STARTING_ANCHOR_ROOT
```

Expected result:

- `OUTPUT_ROOT == STARTING_ANCHOR_ROOT`

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

This is a zeronet task, so task-origin validation is not required.

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

- `AnchorStateRegistry` proxy implementation equals the newly deployed `anchorStateRegistryImpl`
- `AnchorStateRegistry.anchorGame()` equals `address(0)`
- `AnchorStateRegistry.getStartingAnchorRoot()` equals `STARTING_ANCHOR_ROOT` / `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `AnchorStateRegistry.getAnchorRoot()` equals `STARTING_ANCHOR_ROOT` / `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `AnchorStateRegistry.respectedGameType()` equals `GAME_TYPE`
- `AnchorStateRegistry.disputeGameFinalityDelaySeconds()` is unchanged
- `AnchorStateRegistry.initVersion()` increments by one
- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` equals the configured `TEE_IMAGE_HASH`
- `aggregateVerifier.ZK_RANGE_HASH()` equals the configured `ZK_RANGE_HASH`
- `aggregateVerifier.ZK_AGGREGATE_HASH()` equals the configured `ZK_AGGREGATE_HASH`
- all other `AggregateVerifier` immutables (`ZK_VERIFIER`, `TEE_VERIFIER`, `DELAYED_WETH`, `CONFIG_HASH`, etc.) match the previous `AggregateVerifier`
