# Replay Update ZK Config

Status: READY TO SIGN

## Description

This task replays the ZK verifier portion of `zeronet/2026-04-21-update-zk-config` after the Zeronet re-genesis.

It deploys a new `ZkVerifier`, deploys a new `AggregateVerifier` wired to it, and points `DisputeGameFactory.gameImpls(gameType)` at the new `AggregateVerifier`.

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
