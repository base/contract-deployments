# Upgrade ZK and TEE Hash

Status: READY TO SIGN

## Transactions

- New `AggregateVerifier` deployment ([`0x3322f6aBe3EEDd835c24323e27B0433e701e9908`](https://hoodi.etherscan.io/address/0x3322f6aBe3EEDd835c24323e27B0433e701e9908)): [`0x017a351436eaba6d08bb7bd28554c48d638e5ad78ff4cd589c1f617157939c87`](https://hoodi.etherscan.io/tx/0x017a351436eaba6d08bb7bd28554c48d638e5ad78ff4cd589c1f617157939c87) (artefacts: [run-1781032840067.json](./records/DeployAggregateVerifier.s.sol/560048/run-1781032840067.json))

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
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
