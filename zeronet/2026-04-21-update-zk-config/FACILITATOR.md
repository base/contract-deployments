# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-21-update-zk-config
make deps
make deploy-zk-verifier
make deploy-aggregate-verifier
make deploy-anchor-state-registry
```

`make deploy-zk-verifier` runs `DeployZkVerifier`:

- deploys the `ZkVerifier` used by this task
- writes `zkVerifier` to `addresses.json`

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the existing one, overriding `ZK_VERIFIER`, `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- writes `aggregateVerifier` to `addresses.json`

`make deploy-anchor-state-registry` runs `DeployAnchorStateRegistry`:

- deploys the next `AnchorStateRegistry` implementation with the same finality delay as the live proxy
- writes `anchorStateRegistryImpl` to `addresses.json`

Expected `addresses.json` keys:

- `zkVerifier`
- `aggregateVerifier`
- `anchorStateRegistryImpl`

## Pre-sign check: `STARTING_ANCHOR_*` correctness

`STARTING_ANCHOR_ROOT` and `STARTING_ANCHOR_L2_BLOCK_NUMBER` are chain-critical.
Before collecting signatures, verify both values against the target RPC endpoints.

### 1. Validate that the anchor block number is expected

Confirm `STARTING_ANCHOR_L2_BLOCK_NUMBER` matches the planned cutover value.

```bash
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
cast block $BLOCK --rpc-url $L2_RPC_URL
```

### 2. Derive output root from that exact block

Use `optimism_outputAtBlock` with the same block and compare to `STARTING_ANCHOR_ROOT` from `.env`.

```bash
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock $(cast 2h $BLOCK) --rpc-url $OP_NODE_RPC_URL | jq -r '.outputRoot')
echo $OUTPUT_ROOT
echo $STARTING_ANCHOR_ROOT
```

Expected result:

- `OUTPUT_ROOT == STARTING_ANCHOR_ROOT`

### 3. RPC requirements

- `L2_RPC_URL` should point to the target L2 execution RPC.
- `OP_NODE_RPC_URL` must expose `optimism_outputAtBlock`.
- Depending on block age and provider retention, an archive-capable RPC may be required.

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-21-update-zk-config
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
cd zeronet/2026-04-21-update-zk-config
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

- `AnchorStateRegistry` proxy implementation equals the newly deployed `anchorStateRegistryImpl`
- `AnchorStateRegistry.anchorGame()` equals `address(0)`
- `AnchorStateRegistry.getStartingAnchorRoot()` equals the configured `STARTING_ANCHOR_ROOT` and `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `zkVerifier.SP1_VERIFIER()` equals the configured `SP1_VERIFIER`
- `aggregateVerifier.ZK_VERIFIER()` equals the newly deployed `zkVerifier`
- `aggregateVerifier.TEE_IMAGE_HASH()` equals the configured `TEE_IMAGE_HASH`
- `aggregateVerifier.ZK_RANGE_HASH()` equals the configured `ZK_RANGE_HASH`
- `aggregateVerifier.ZK_AGGREGATE_HASH()` equals the configured `ZK_AGGREGATE_HASH`
