# Update Mainnet Incident Multisig Signers

Status: READY TO SIGN

## Description

This task updates the owner set for the Mainnet Incident Multisig.

It adds one signer and removes two signers. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

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

- Select `mainnet/2026-07-17-incident-multisig-signers`.
- Select `base-signer.json` to sign for the Incident Multisig.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
