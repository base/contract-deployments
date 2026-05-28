# Upgrade ZK and TEE Hash

Status: READY TO SIGN

## Transactions

- New `AggregateVerifier` deployment ([`0x3a80c85f3Ac6C305B2F8f869A35e70D821Ab7c3a`](https://hoodi.etherscan.io/address/0x3a80c85f3Ac6C305B2F8f869A35e70D821Ab7c3a)): [`0xaa13b9f1a738e6cde840cc0993cb9120e4ef42e6f404df5c54e6c903c027aa9e`](https://hoodi.etherscan.io/tx/0xaa13b9f1a738e6cde840cc0993cb9120e4ef42e6f404df5c54e6c903c027aa9e) (artefacts: [run-1779995783324.json](./records/DeployAggregateVerifier.s.sol/560048/run-1779995783324.json))

## Description

This task updates the TEE and ZK verifier hashes of the multiproof implementation on `zeronet`.

- redeploying `AggregateVerifier` with identical immutables, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
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
