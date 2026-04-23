# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-23-fix-starting-anchor-root
make deps
make deploy-anchor-state-registry
```

`make deploy-anchor-state-registry` runs `DeployAnchorStateRegistry`:

- deploys the next `AnchorStateRegistry` implementation with the same finality delay as the live proxy
- writes `anchorStateRegistryImpl` to `addresses.json`

Expected `addresses.json` key:

- `anchorStateRegistryImpl`

## Pre-sign check: `STARTING_ANCHOR_*` correctness

Use the proofs RPC for this check:

```bash
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock $(cast 2h $BLOCK) --rpc-url https://base-zeronet-reth-proofs-donotuse.cbhq.net:7545 | jq -r '.outputRoot')
echo $OUTPUT_ROOT
echo $STARTING_ANCHOR_ROOT
```

Expected result:

- `OUTPUT_ROOT == STARTING_ANCHOR_ROOT`

## Generate validation files

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-23-fix-starting-anchor-root
make deps
make gen-validation-fix-starting-anchor-root-cb
make gen-validation-fix-starting-anchor-root-sc
```

This produces:

- `validations/fix-starting-anchor-root-cb-signer.json`
- `validations/fix-starting-anchor-root-sc-signer.json`

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-23-fix-starting-anchor-root
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-fix-starting-anchor-root-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-fix-starting-anchor-root-sc
```

### 4. Execute upgrade batch

```bash
make execute-fix-starting-anchor-root
```

Post-checks enforced by script:

- `AnchorStateRegistry` proxy implementation equals the newly deployed `anchorStateRegistryImpl`
- `AnchorStateRegistry.anchorGame()` equals `address(0)`
- `AnchorStateRegistry.getStartingAnchorRoot()` equals the corrected `STARTING_ANCHOR_ROOT` and `STARTING_ANCHOR_L2_BLOCK_NUMBER`
