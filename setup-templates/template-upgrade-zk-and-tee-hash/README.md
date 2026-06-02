# Upgrade ZK and TEE Hash

Status: READY TO SIGN

## Description

This template updates the TEE and ZK verifier hashes of a multiproof implementation by:

- redeploying `AggregateVerifier` with identical immutables, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- pointing `DisputeGameFactory.gameImpls(gameType)` at the new `AggregateVerifier`

## Setup

From the repository root:

```bash
make setup-upgrade-zk-and-tee-hash network=<network>
cd <network>/<date>-upgrade-zk-and-tee-hash
```

Fill in all required values in `.env`:

- `BASE_CONTRACTS_COMMIT`
- `GAME_TYPE`
- `TEE_IMAGE_HASH`
- `ZK_RANGE_HASH`
- `ZK_AGGREGATE_HASH`
- `PROXY_ADMIN_OWNER`
- `DISPUTE_GAME_FACTORY_PROXY`

Then install dependencies and build:

```bash
make deps
forge build
```

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
