# Replay TEE Registry and Nitro Fixes

Status: READY TO SIGN

## Description

This task replays the next Zeronet historical tasks after the re-genesis multiproof activation:

- `2026-04-07-upgrade-tee-registry-nitro`
- `2026-04-17-fix-nitro-verifier`
- `2026-04-17-fix-tee-image-hash`

The replay deploys the NitroEnclaveVerifier with the corrected verifier ID, deploys a TEEProverRegistry implementation that points at it, and registers an AggregateVerifier with the corrected TEE image hash. Because this is a re-genesis replay, the April 17 fixes are applied at deployment time instead of recreating the faulty intermediate verifier ID and TEE image hash.

## Procedure

## Sign task

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

```bash
cd contract-deployments
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
