# Update ZK Config

Status: READY TO SIGN

## Description

This task updates the verifier configuration of the multiproof implementation on `sepolia`.

- deploying a new `ZkVerifier`
- redeploying `AggregateVerifier` with identical immutables, overriding `ZK_VERIFIER` and `ZK_RANGE_HASH`
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
