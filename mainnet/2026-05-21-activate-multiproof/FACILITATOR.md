# Facilitator Guide

This task executes on Ethereum mainnet L1 and configures Base mainnet dispute games (`L2_CHAIN_ID=8453`).

## 1. Prepare Repo

```bash
cd contract-deployments
git pull
cd mainnet/2026-05-21-activate-multiproof
make deps
```

## 2. Deploy Contracts

```bash
make deploy-nitro-verifier
make deploy-multiproof
make setup-nitro
```

Confirm `addresses.json` contains every deployed address required by `script/ActivateMultiproofStack.s.sol`.

## 3. Verify Task Inputs

Before collecting signatures, verify `.env` and `addresses.json` match the intended mainnet cutover.

Pay particular attention to:

- `STARTING_ANCHOR_L2_BLOCK_NUMBER`
- `STARTING_ANCHOR_ROOT`
- deployed contract addresses in `addresses.json`
- mainnet safe and proxy addresses re-exported at the end of `.env`

Derive the anchor root from the exact Base mainnet block and compare it to `.env`:

```bash
BLOCK=$STARTING_ANCHOR_L2_BLOCK_NUMBER
cast block $BLOCK --rpc-url $L2_RPC_URL
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock $(cast 2h $BLOCK) --rpc-url $OP_NODE_RPC_URL | jq -r '.outputRoot')
echo $OUTPUT_ROOT
echo $STARTING_ANCHOR_ROOT
```

Expected result: `OUTPUT_ROOT == STARTING_ANCHOR_ROOT`.

## 4. Generate Validation Files

```bash
make gen-validation-multiproof-cb
make gen-validation-multiproof-sc
```

Review and finalize:

- `validations/multiproof-cb-signer.json`
- `validations/multiproof-sc-signer.json`

Mainnet validation files must not contain `skipTaskOriginValidation`.

## 5. Collect Task Origin Signatures

After `.env`, `addresses.json`, and validation files are final, collect task origin signatures.

Follow `TASK_ORIGIN.md`.

## 6. Collect Signer Signatures

Ask signers to follow `README.md` and return their signer-tool signatures.

Collect signatures for:

- `CB_MULTISIG`
- `BASE_SECURITY_COUNCIL`

## 7. Approve From Both Safes

Concatenate the signer signatures for `CB_MULTISIG`, then approve:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-multiproof-cb
```

Concatenate the signer signatures for `BASE_SECURITY_COUNCIL`, then approve:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-multiproof-sc
```

## 8. Execute Activation

```bash
make execute-activate-multiproof
```
