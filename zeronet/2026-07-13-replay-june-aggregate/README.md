# Replay June Aggregate

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x605604d4e228834efb5ab8266518d7c4ef3827073d77ed30d168104b3b729ea2)

## Description

This task replays the June Zeronet historical tasks that share `BASE_CONTRACTS_COMMIT=e225648a7ed538e7e28c041d44f3b7a606ba7743` after the Zeronet re-genesis:

- `2026-06-02-upgrade-zk-and-tee-hash`
- `2026-06-09-upgrade-zk-and-tee-hash`
- `2026-06-13-upgrade-zk-and-tee-hash`

It deploys one final replay `AggregateVerifier` with the final TEE, ZK, and config hashes from the June task group, then points `DisputeGameFactory.gameImpls(gameType)` at it.

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
