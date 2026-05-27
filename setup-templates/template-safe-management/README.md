# Update Sepolia Incident Multisig Signers

Status: TODO[READY TO SIGN|EXECUTED]

## Description

We wish to update the owners of our Incident Multisig to be consistent with the current state of our Base Chain Eng team. This involves removing signers that are no longer closely involved with the team, and adding new team members as signers. The exact signer changes are outlined in the [OwnerDiff.json](./OwnerDiff.json) file.

## Approving Signers Update

### 1. Update repo:

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool (NOTE: do not enter the task directory. Run this command from the project's root).

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Be sure to select the correct task from the list of available tasks to sign.

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
