# Update Sepolia Incident Multisig Signers

Status: READY TO SIGN

## Description

We wish to update the owners of our [Incident Multisig](https://sepolia.etherscan.io/address/0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f) on Sepolia to be consistent with the current state of our Base Chain Eng team. This involves removing signers that are no longer closely involved with the team, and adding new team members as signers. The exact signer changes are outlined in the [OwnerDiff.json](./OwnerDiff.json) file.

The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json), and the simulation sender is configured in [.env](./.env).

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

### 2. Install Node.js if needed

First, check if you have node installed

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node

```bash
brew install node
```

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

Task name: `sepolia/2026-05-13-incident-multisig-signers`

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
