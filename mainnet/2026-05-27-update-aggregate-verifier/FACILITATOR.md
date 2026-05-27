# Facilitator Guide

This task executes on Ethereum mainnet L1 and rotates the multiproof
`AggregateVerifier` registered for Base mainnet game type `621`
(`L2_CHAIN_ID=8453`).

## 1. Prepare Repo

```bash
cd contract-deployments
git pull
cd mainnet/2026-05-27-update-aggregate-verifier
make deps
```

## 2. Fill In Placeholder Hashes

Before deploying, replace the placeholder values in `.env`:

- `TEE_IMAGE_HASH`
- `ZK_RANGE_HASH`
- `ZK_AGGREGATE_HASH`

`CONFIG_HASH`, `BLOCK_INTERVAL`, `INTERMEDIATE_BLOCK_INTERVAL`, and every
reused stack component (`DELAYED_WETH_PROXY`, `TEE_VERIFIER`, `ZK_VERIFIER`,
`ANCHOR_STATE_REGISTRY_PROXY`) are intentionally unchanged from
`mainnet/2026-05-21-activate-multiproof` — do not modify them.

## 3. Deploy The New AggregateVerifier

```bash
make deploy-aggregate-verifier
```

Confirm `addresses.json` is updated with the new `aggregateVerifier` and that
the post-checks in `script/DeployAggregateVerifier.s.sol` passed.

## 4. Verify Task Inputs

Before collecting signatures, verify `.env` and `addresses.json` match the
intended cutover. Pay particular attention to:

- the three new hashes (`TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, `ZK_AGGREGATE_HASH`)
- `aggregateVerifier` in `addresses.json`
- `OLD_AGGREGATE_VERIFIER` in `.env` (this must equal the current
  `DisputeGameFactory.gameImpls(621)`):

```bash
cast call $DISPUTE_GAME_FACTORY_PROXY "gameImpls(uint32)(address)" $GAME_TYPE \
  --rpc-url $L1_RPC_URL
echo $OLD_AGGREGATE_VERIFIER
```

Expected: the two values match.

## 5. Generate Validation Files

```bash
make gen-validation-set-impl-cb
make gen-validation-set-impl-sc
make gen-validation-rollback-cb
make gen-validation-rollback-sc
```

Review and finalize:

- `validations/coinbase-signer.json`
- `validations/security-council-signer.json`
- `validations/coinbase-signer-rollback.json`
- `validations/security-council-signer-rollback.json`

Mainnet validation files must not contain `skipTaskOriginValidation`.

## 6. Collect Task Origin Signatures

After `.env`, `addresses.json`, and validation files are final, collect task
origin signatures. Follow `TASK_ORIGIN.md`.

## 7. Collect Signer Signatures

Ask signers to follow `README.md` and return their signer-tool signatures.
Collect signatures for both the upgrade and rollback flows for:

- `CB_MULTISIG`
- `BASE_SECURITY_COUNCIL`

## 8. Approve The Upgrade From Both Safes

Concatenate the upgrade signer signatures for `CB_MULTISIG`, then approve:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-set-impl-cb
```

Concatenate the upgrade signer signatures for `BASE_SECURITY_COUNCIL`, then
approve:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-set-impl-sc
```

## 9. Execute The Upgrade

```bash
make execute-set-impl
```

## (**ONLY** if needed) Execute Rollback

> [!IMPORTANT]
>
> THIS SHOULD ONLY BE PERFORMED IN THE EVENT THAT WE NEED TO ROLLBACK.

### 1. Approve rollback with CB Multisig signatures

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-rollback-cb
```

### 2. Approve rollback with Security Council signatures

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
SIGNATURES=$SIGNATURES make approve-rollback-sc
```

### 3. Execute rollback

```bash
make execute-rollback
```
