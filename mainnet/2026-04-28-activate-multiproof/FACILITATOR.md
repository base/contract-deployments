# Facilitator Guide

Guide for facilitators managing this task.

## Task Origin Signing

After setting up the task, generate cryptographic attestations to prove who created and facilitated the task. These signatures are stored in `mainnet/signatures/2026-04-28-activate-multiproof/`.

### Task creator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-task-creator
```

### Base facilitator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-base-facilitator
```

### Security Council facilitator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-sc-facilitator
```

## Finalize task inputs

Before collecting signatures, confirm that the task parameters in `.env` match the intended mainnet cutover values.

Revalidate `STARTING_ANCHOR_*` against mainnet before collecting signatures.

## Deployment prerequisites

Before collecting signatures, complete all deploy steps:

```bash
cd contract-deployments
git pull
cd mainnet/2026-04-28-activate-multiproof
make deps
make deploy-nitro-verifier
make deploy-multiproof
make setup-nitro
```

`make deps` applies the local `AnchorStateRegistry` patch so the ASR reinitializer clears the old `anchorGame` pointer and the new `STARTING_ANCHOR_*` values take effect after cutover.

`make deploy-nitro-verifier` deploys `NitroEnclaveVerifier` and wires the RiscZero verify route using the configured `RISC0_SET_VERIFIER`. Initializes `addresses.json`.

`make deploy-multiproof` deploys the remaining contracts (`TEEProverRegistry`, `DelayedWETH`, `TEEVerifier`, `ZkVerifier`, `AggregateVerifier`, etc.). The `TEEProverRegistry` and `DelayedWETH` proxies are initialized at deploy time and their admin is transferred to the L1 `ProxyAdmin`. Appends addresses to `addresses.json`.

`make setup-nitro` configures the `NitroEnclaveVerifier`: sets the `proofSubmitter` to the `TEEProverRegistry` proxy and transfers ownership to `TEE_PROVER_REGISTRY_OWNER`. This step runs directly via the deployer Ledger.

The activation batch upgrades the L1 proxies, registers the new multiproof game type, and disables new `CANNON` game creation.

Expected `addresses.json` keys:

- `nitroEnclaveVerifier`
- `teeProverRegistryImpl`
- `teeProverRegistryProxy`
- `teeVerifier`
- `zkVerifier`
- `delayedWETHImpl`
- `delayedWETHProxy`
- `aggregateVerifier`
- `optimismPortal2Impl`
- `disputeGameFactoryImpl`
- `anchorStateRegistryImpl`

## Generate validation files

```bash
cd contract-deployments
git pull
cd mainnet/2026-04-28-activate-multiproof
make deps
make gen-validation-multiproof-cb
make gen-validation-multiproof-sc
```

This produces:

- `validations/multiproof-cb-signer.json`
- `validations/multiproof-sc-signer.json`

Mainnet validation files must not contain `skipTaskOriginValidation`.

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

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd mainnet/2026-04-28-activate-multiproof
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
