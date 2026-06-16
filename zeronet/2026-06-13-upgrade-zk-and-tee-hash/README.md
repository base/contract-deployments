# Upgrade ZK and TEE Hash + Anchor Root

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0xc396a2cdf6e5ac421b3f3530b31767c60977a127b7cb4c316b9ba1bc2808a3c7)

## Transactions

- New `AggregateVerifier` deployment ([`0xbdF244c72D059039Ac3332B7D759e1F1380d03DA`](https://hoodi.etherscan.io/address/0xbdF244c72D059039Ac3332B7D759e1F1380d03DA)): [`0xc38dc268da2486e5734de4de9b12b5456dd054abbc10acdffba3c2791365cd4f`](https://hoodi.etherscan.io/tx/0xc38dc268da2486e5734de4de9b12b5456dd054abbc10acdffba3c2791365cd4f) (artefacts: [run-1781319464299.json](./records/DeployAggregateVerifier.s.sol/560048/run-1781319464299.json))
- New `AnchorStateRegistry` implementation deployment ([`0x2d87aFA7b2871Ac90732E96974cefE4C3DD2c025`](https://hoodi.etherscan.io/address/0x2d87aFA7b2871Ac90732E96974cefE4C3DD2c025)): [`0x224ccdd61ebd56a642242db00117978c17d9db094d2c3af9b49e6d9a9a3568d5`](https://hoodi.etherscan.io/tx/0x224ccdd61ebd56a642242db00117978c17d9db094d2c3af9b49e6d9a9a3568d5) (artefacts: [run-1781550547058.json](./records/DeployAnchorStateRegistry.s.sol/560048/run-1781550547058.json))
- Coinbase Multisig approval ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0xb011c7d24de3e9eeea5d754709062fe96ca9f8b56b579aa23c928e4ca3b1d72e`](https://hoodi.etherscan.io/tx/0xb011c7d24de3e9eeea5d754709062fe96ca9f8b56b579aa23c928e4ca3b1d72e) (artefacts: [run-1781574254160.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781574254160.json))
- Security Council approval ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0xbce56bf10d42073b423c051ae060d6026ef490a1d063bf44f0689cbe9227d6b5`](https://hoodi.etherscan.io/tx/0xbce56bf10d42073b423c051ae060d6026ef490a1d063bf44f0689cbe9227d6b5) (artefacts: [run-1781574326926.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781574326926.json))
- Execute via Proxy Admin Owner ([`0x3d59999977e0896ee1f8783bB8251DF16fb483E9`](https://hoodi.etherscan.io/address/0x3d59999977e0896ee1f8783bB8251DF16fb483E9)): [`0xc396a2cdf6e5ac421b3f3530b31767c60977a127b7cb4c316b9ba1bc2808a3c7`](https://hoodi.etherscan.io/tx/0xc396a2cdf6e5ac421b3f3530b31767c60977a127b7cb4c316b9ba1bc2808a3c7) (artefacts: [run-1781574422159.json](./records/UpdateVerifierHashes.s.sol/560048/run-1781574422159.json))

## Description

This task updates the TEE and ZK verifier hashes of the multiproof implementation on `zeronet` and resets the `AnchorStateRegistry` starting anchor root.

- redeploying `AggregateVerifier` with identical immutables, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- deploying a new `AnchorStateRegistry` implementation with the same finality delay and bumped init version
- upgrading and reinitializing `AnchorStateRegistry` with `STARTING_ANCHOR_ROOT` / `STARTING_ANCHOR_L2_BLOCK_NUMBER`, clearing the stale `anchorGame`
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
