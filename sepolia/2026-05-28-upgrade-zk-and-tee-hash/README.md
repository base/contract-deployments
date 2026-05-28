# Upgrade ZK and TEE Hash

Status: READY TO SIGN

## Transactions

- New `AggregateVerifier` deployment ([`0xeCe9c5b9DCa09f1a0Ed85DA97f8F1396dC5634Ce`](https://sepolia.etherscan.io/address/0xeCe9c5b9DCa09f1a0Ed85DA97f8F1396dC5634Ce)): [`0xaef9dc2499802c3d437da82b2a9c39da785ca23b5c3a135672b80a99306a7ac4`](https://sepolia.etherscan.io/tx/0xaef9dc2499802c3d437da82b2a9c39da785ca23b5c3a135672b80a99306a7ac4) (artefacts: [run-1779990011323.json](./records/DeployAggregateVerifier.s.sol/11155111/run-1779990011323.json))

## Description

This task updates the TEE and ZK verifier hashes of the multiproof implementation on `sepolia`.

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
