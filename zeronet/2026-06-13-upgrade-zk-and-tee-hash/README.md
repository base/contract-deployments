# Upgrade ZK and TEE Hash + Anchor Root

Status: READY TO SIGN

## Transactions

- New `AggregateVerifier` deployment ([`0xbdF244c72D059039Ac3332B7D759e1F1380d03DA`](https://hoodi.etherscan.io/address/0xbdF244c72D059039Ac3332B7D759e1F1380d03DA)): [`0xc38dc268da2486e5734de4de9b12b5456dd054abbc10acdffba3c2791365cd4f`](https://hoodi.etherscan.io/tx/0xc38dc268da2486e5734de4de9b12b5456dd054abbc10acdffba3c2791365cd4f) (artefacts: [run-1781319464299.json](./records/DeployAggregateVerifier.s.sol/560048/run-1781319464299.json))

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
