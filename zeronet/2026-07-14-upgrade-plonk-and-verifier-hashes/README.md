# Upgrade PLONK and Verifier Hashes

Status: READY TO SIGN

## Description

This task switches Zeronet multiproof ZK verification to SP1 PLONK and updates the ZK verification keys.

- adds the SP1 PLONK v6.1.0 route and freezes Groth16 on the existing PAO-owned gateway
- redeploys `AggregateVerifier` with the new `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH` (preserves `TEE_IMAGE_HASH`)
- points `DisputeGameFactory.gameImpls(621)` at the new `AggregateVerifier`

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run the signing tool

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
