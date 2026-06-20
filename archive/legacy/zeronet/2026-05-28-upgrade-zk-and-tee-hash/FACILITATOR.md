# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-28-upgrade-zk-and-tee-hash
make deps
make deploy-aggregate-verifier VERIFIER_API_KEY=...
make deploy-anchor-state-registry VERIFIER_API_KEY=...
```

`make deps` runs `task-extra-deps` and then `apply-patches`, which patches
`lib/contracts/src/dispute/AnchorStateRegistry.sol` to bump
`ReinitializableBase(2)` to `ReinitializableBase(5)` (matching the live proxy's
`initVersion() + 1 = 5`) and to clear `anchorGame` inside `initialize()`.

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- reuses the existing `ZkVerifier` from the current on-chain AggregateVerifier
- writes `aggregateVerifier` to `addresses.json`

`make deploy-anchor-state-registry` runs `DeployAnchorStateRegistry`:

- snapshots `disputeGameFinalityDelaySeconds` and `initVersion` from the live ASR proxy
- deploys a new `AnchorStateRegistry` impl preserving the finality delay
- asserts `nextImpl.initVersion() == currentInitVersion + 1`
- writes `anchorStateRegistryImpl` to `addresses.json`

Expected `addresses.json` keys:

- `aggregateVerifier`
- `anchorStateRegistryImpl`

## Pre-sign check: `STARTING_ANCHOR_*` correctness

`STARTING_ANCHOR_ROOT` and `STARTING_ANCHOR_L2_BLOCK_NUMBER` are chain-critical.
Before collecting signatures, verify both values against the zeronet op-node
proofs RPC.

### 1. Validate the anchor block number is recent and finalised

Confirm `STARTING_ANCHOR_L2_BLOCK_NUMBER` from `.env` is at or below the
finalised L2 block:

```bash
cast rpc optimism_syncStatus --rpc-url https://base-zeronet-reth-proofs-donotuse.cbhq.net:7545 \
  | jq -r '.finalized_l2.number'
```

Expected result:

- `finalized_l2.number >= STARTING_ANCHOR_L2_BLOCK_NUMBER`.

### 2. Validate the anchor root matches the chain

Use `optimism_outputAtBlock` with the same block and compare to
`STARTING_ANCHOR_ROOT` from `.env`:

```bash
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock $(cast 2h $BLOCK) \
  --rpc-url https://base-zeronet-reth-proofs-donotuse.cbhq.net:7545 | jq -r '.outputRoot')
echo $OUTPUT_ROOT
echo $STARTING_ANCHOR_ROOT
```

Expected result:

- `OUTPUT_ROOT == STARTING_ANCHOR_ROOT`.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-28-upgrade-zk-and-tee-hash
make deps
make gen-validation-update-verifier-hashes-cb
make gen-validation-update-verifier-hashes-sc
```

This produces:

- `validations/coinbase-signer.json`
- `validations/security-council-signer.json`

### Disable task-origin validation

This task does not ship task-origin signatures. After generating the two
validation files, ensure each one carries the following field at the JSON
root (add it if the signer-tool did not emit it automatically):

```json
"skipTaskOriginValidation": true
```

Commit both files only after that field is set; otherwise signers' UI will
demand task-origin attestations that do not exist for this task.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-28-upgrade-zk-and-tee-hash
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
- `AnchorStateRegistry.anchorGame() == address(0)` (stale anchor game cleared)
- `AnchorStateRegistry.getStartingAnchorRoot()` root + l2SequenceNumber equal `STARTING_ANCHOR_ROOT` / `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `AnchorStateRegistry.getAnchorRoot()` equals the same
- `AnchorStateRegistry.respectedGameType()` equals `GAME_TYPE`
- `AnchorStateRegistry.disputeGameFinalityDelaySeconds()` unchanged from before
- `AnchorStateRegistry.initVersion() == previous + 1`
- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` equals the configured `TEE_IMAGE_HASH`
- `aggregateVerifier.ZK_RANGE_HASH()` equals the configured `ZK_RANGE_HASH`
- `aggregateVerifier.ZK_AGGREGATE_HASH()` equals the configured `ZK_AGGREGATE_HASH`
- All other AggregateVerifier immutables (ZK_VERIFIER, TEE_VERIFIER, DELAYED_WETH, CONFIG_HASH, etc.) match the previous AggregateVerifier
