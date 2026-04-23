# Fix Starting Anchor Root

Status: READY TO SIGN

## Description

This task corrects the starting anchor root in `AnchorStateRegistry` on `zeronet`.

- deploying a new `AnchorStateRegistry` implementation
- upgrading and reinitializing `AnchorStateRegistry` with the corrected starting anchor root

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
