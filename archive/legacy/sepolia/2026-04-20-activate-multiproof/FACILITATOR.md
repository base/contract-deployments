# Facilitator Guide

Guide for facilitators managing this task.

## Finalize task inputs

Before collecting signatures, confirm that the task parameters in `.env` match the intended Sepolia cutover values.

Revalidate `STARTING_ANCHOR_*` against Sepolia before collecting signatures.

## Deployment prerequisites

Before collecting signatures, complete all deploy steps:

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-20-activate-multiproof
make deps
make deploy-nitro-verifier
make deploy-multiproof
make setup-nitro
```

There is no `make deploy-cb-multicall` step here because `CBMulticall` is already deployed on Sepolia.

`make deps` also reapplies the local `AnchorStateRegistry` patch so the ASR reinitializer clears the old `anchorGame` pointer and the new `STARTING_ANCHOR_*` values actually take effect after cutover.

`make deploy-nitro-verifier` deploys `NitroEnclaveVerifier` (with the deployer as temporary owner) and wires the RiscZero verify route. Initializes `addresses.json`.

`make deploy-multiproof` deploys the remaining contracts (`TEEProverRegistry`, `DelayedWETH`, `TEEVerifier`, `AggregateVerifier`, etc.). The `TEEProverRegistry` and `DelayedWETH` proxies are initialized at deploy time and their admin is transferred to the L1 `ProxyAdmin`. Appends addresses to `addresses.json`.

`make setup-nitro` configures the `NitroEnclaveVerifier`: sets the `proofSubmitter` to the `TEEProverRegistry` proxy and transfers ownership to `TEE_PROVER_REGISTRY_OWNER`. This step runs directly via the deployer Ledger (no multisig signatures required).

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-20-activate-multiproof
make deps
make gen-validation-multiproof-cb
make gen-validation-multiproof-sc
```

This produces:

- `validations/multiproof-cb-signer.json`
- `validations/multiproof-sc-signer.json`

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
- `OP_NODE_RPC_URL` must expose `optimism_outputAtBlock` (typically an OP node RPC).
- Depending on block age and provider retention, an archive-capable RPC may be required.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-04-20-activate-multiproof
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-multiproof-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-multiproof-sc
```

### 4. Execute the multiproof activation batch

```bash
make execute-activate-multiproof
```
