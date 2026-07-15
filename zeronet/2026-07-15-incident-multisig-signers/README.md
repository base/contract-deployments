# Update Zeronet Incident Multisig Signers

Status: READY TO SIGN

## Description

This task updates the owner set for the Zeronet Incident Multisig and mock Security Council Safe.

It adds one signer and removes two signers from each Safe. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

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

- Select `zeronet/2026-07-15-incident-multisig-signers`.
- Select `base-signer.json` to sign for the Incident Multisig.
- Select `security-council-signer.json` to sign for the mock Security Council Safe.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
