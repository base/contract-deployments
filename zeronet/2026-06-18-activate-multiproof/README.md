# Activate Multiproof

Status: PREPARED (regenesis 2026-06-18) — multiproof hashes filled & verified; pending live L1 deploy for the new addresses + genesis anchor root. Cloned from 2026-04-01-activate-multiproof.

## Description

This task activates multiproof on `zeronet`.

This task does not include the proposer-side follow-up steps after the upgrade.

## Procedure

## Sign Task

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
