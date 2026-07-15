# Replay May Aggregate

Status: READY TO SIGN

## Description

This task replays the May Zeronet historical tasks that share `BASE_CONTRACTS_COMMIT=1baa168c9db6a946ae47863ea07295bedb3599a6` after the Zeronet re-genesis:

- `2026-05-18-upgrade-zk-and-tee-hash`
- `2026-05-21-update-nitro-verifier-id`
- `2026-05-22-increase-gas-and-elasticity-limit`
- `2026-05-22-increase-max-gas-limit`
- `2026-05-28-upgrade-zk-and-tee-hash`
- `2026-05-31-update-sp1-gateway`

It updates the Nitro verifier ID, raises the `SystemConfig` gas limits and EIP-1559 parameters, deploys a PROXY_ADMIN_OWNER-owned SP1 gateway, and points `DisputeGameFactory.gameImpls(gameType)` at the final replay `AggregateVerifier`.

Base signers may be asked to sign twice: once for the Nitro verifier ID update and once for the replay batch approval.

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
