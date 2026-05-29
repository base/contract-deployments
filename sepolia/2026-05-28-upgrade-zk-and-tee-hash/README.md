# Upgrade ZK and TEE Hash

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xe6b2fde0ac66fc17e5ecb6b56aaa0eddbc567130ad66a9dff2c25376320f8e32)

## Transactions

- New `AggregateVerifier` deployment ([`0xeCe9c5b9DCa09f1a0Ed85DA97f8F1396dC5634Ce`](https://sepolia.etherscan.io/address/0xeCe9c5b9DCa09f1a0Ed85DA97f8F1396dC5634Ce)): [`0xaef9dc2499802c3d437da82b2a9c39da785ca23b5c3a135672b80a99306a7ac4`](https://sepolia.etherscan.io/tx/0xaef9dc2499802c3d437da82b2a9c39da785ca23b5c3a135672b80a99306a7ac4) (artefacts: [run-1779990011323.json](./records/DeployAggregateVerifier.s.sol/11155111/run-1779990011323.json))
- Coinbase Multisig approval ([`0x646132A1667ca7aD00d36616AFBA1A28116C770A`](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A)): [`0x33465e04d448f1627adfd6130fa2765bd672d0280a4aa190e79fd780d9d29d48`](https://sepolia.etherscan.io/tx/0x33465e04d448f1627adfd6130fa2765bd672d0280a4aa190e79fd780d9d29d48) (artefacts: [run-1780059720699.json](./records/UpdateVerifierHashes.s.sol/11155111/run-1780059720699.json))
- Security Council approval ([`0x6AF0674791925f767060Dd52f7fB20984E8639d8`](https://sepolia.etherscan.io/address/0x6AF0674791925f767060Dd52f7fB20984E8639d8)): [`0x91f51a84ac2100ea2da72e9555ac423ef169f43239197a31a4d4e313b1f77838`](https://sepolia.etherscan.io/tx/0x91f51a84ac2100ea2da72e9555ac423ef169f43239197a31a4d4e313b1f77838) (artefacts: [run-1780060056610.json](./records/UpdateVerifierHashes.s.sol/11155111/run-1780060056610.json))
- Execute via Proxy Admin Owner ([`0x0fe884546476dDd290eC46318785046ef68a0BA9`](https://sepolia.etherscan.io/address/0x0fe884546476dDd290eC46318785046ef68a0BA9)): [`0xe6b2fde0ac66fc17e5ecb6b56aaa0eddbc567130ad66a9dff2c25376320f8e32`](https://sepolia.etherscan.io/tx/0xe6b2fde0ac66fc17e5ecb6b56aaa0eddbc567130ad66a9dff2c25376320f8e32) (artefacts: [run-1780060104597.json](./records/UpdateVerifierHashes.s.sol/11155111/run-1780060104597.json))

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
