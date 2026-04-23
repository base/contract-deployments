# Update ZK Config

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x84511c640a3f316cba8e6d6442ec152e5378013b9adc40b732633f283d2ea2a0)

## Description

This task updates the verifier configuration of the multiproof implementation on `zeronet` and resets the `AnchorStateRegistry` starting anchor root.

- deploying a new `ZkVerifier`
- redeploying `AggregateVerifier` with identical immutables, overriding `ZK_VERIFIER`, `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- deploying a new `AnchorStateRegistry` implementation
- upgrading `AnchorStateRegistry` to seed the new starting anchor root and clear `anchorGame`
- pointing `DisputeGameFactory.gameImpls(gameType)` at the new `AggregateVerifier`

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run signing tool

```bash
cd contract-deployments
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
