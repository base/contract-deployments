# Update ZK Program Hashes

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x5e21320ec98f5a30b07a3ab0d186e13e846601258a255c72443124d3d671a59c)

## Description

This task updates Zeronet multiproof ZK program hashes to match the recent Sepolia PLONK task.

- redeploys `AggregateVerifier` with the new `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH`, preserving all other immutables
- points `DisputeGameFactory.gameImpls(621)` at the new `AggregateVerifier`

## Procedure

1. Run `make sign-task` from `contract-deployments`.
2. Open [http://localhost:3000](http://localhost:3000), select your signer role, and sign the task.
3. Send the signature to the facilitator.

See `FACILITATOR.md` for execution instructions.
