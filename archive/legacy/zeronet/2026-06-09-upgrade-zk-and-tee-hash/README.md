# Upgrade ZK and TEE Hash

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x977266047aba3ac75394dede977badb285e6a9b657e3a768b3f48c7e35af82bb)

## Transactions

- New `AggregateVerifier` deployment ([`0x3322f6aBe3EEDd835c24323e27B0433e701e9908`](https://hoodi.etherscan.io/address/0x3322f6aBe3EEDd835c24323e27B0433e701e9908)): [`0x017a351436eaba6d08bb7bd28554c48d638e5ad78ff4cd589c1f617157939c87`](https://hoodi.etherscan.io/tx/0x017a351436eaba6d08bb7bd28554c48d638e5ad78ff4cd589c1f617157939c87) (artefacts: [run-1781032840067.json](./records/DeployAggregateVerifier.s.sol/560048/run-1781032840067.json))
- Coinbase Multisig approval ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0xb27468bb4585492731805d389bfe2b4a03ff2914e6c6ceb36634955c2175c464`](https://hoodi.etherscan.io/tx/0xb27468bb4585492731805d389bfe2b4a03ff2914e6c6ceb36634955c2175c464) (artefacts: [run-1781038706967.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781038706967.json))
- Security Council approval ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0x1bbe21d6c54cf21757187b6c789b9fe6b242ec409ec9230baf777d3497e302b4`](https://hoodi.etherscan.io/tx/0x1bbe21d6c54cf21757187b6c789b9fe6b242ec409ec9230baf777d3497e302b4) (artefacts: [run-1781038801820.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781038801820.json))
- Execute via Proxy Admin Owner ([`0x3d59999977e0896ee1f8783bB8251DF16fb483E9`](https://hoodi.etherscan.io/address/0x3d59999977e0896ee1f8783bB8251DF16fb483E9)): [`0x977266047aba3ac75394dede977badb285e6a9b657e3a768b3f48c7e35af82bb`](https://hoodi.etherscan.io/tx/0x977266047aba3ac75394dede977badb285e6a9b657e3a768b3f48c7e35af82bb) (artefacts: [run-1781038863298.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781038863298.json))

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
