# Update Zeronet Incident Multisig Signers

Status: READY TO SIGN

## Description

We wish to update the owners of our [Incident Multisig](https://hoodi.etherscan.io/address/0x856611ed7e07d83243b15e93f6321f2df6865852) and [Security Council Safe](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA) on Zeronet to be consistent with the current state of our Base Chain Eng team. This involves removing signers that are no longer closely involved with the team, and adding new team members as signers. The exact signer changes are outlined in the [OwnerDiff.json](./OwnerDiff.json) file and apply to both safes.

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

Task name: `zeronet/2026-05-13-incident-multisig-signers`

Then select the Safe for which you would like to sign:

- Incident Multisig: `validations/base-signer.json`
- Security Council Safe: `validations/base-signer-safe-b.json`

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
