# Update Sepolia Incident Multisig Signers

Status: EXECUTED ([A](https://sepolia.etherscan.io/tx/0x0ddb802cea5022501f2ecd184a5a017ec0eb908a5ac6bf6cb8746c811c630b56) and [B](https://sepolia.etherscan.io/tx/0x7463cc3d0d5d16f55d8eadfbbe1f82b285e2b161cfef498f84f05d52984ccc57))

## Description

We wish to update the owners of our [Incident Multisig](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A) and [Safe B](https://sepolia.etherscan.io/address/0x6AF0674791925f767060Dd52f7fB20984E8639d8) on Sepolia to be consistent with the current state of our Base Chain Eng team. This involves removing signers that are no longer closely involved with the team, and adding new team members as signers. The exact signer changes are outlined in the [OwnerDiff.json](./OwnerDiff.json) file and apply to both safes.

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

Then select the Safe for which you would like to sign:

- Incident Multisig: `validations/base-signer.json`
- Safe B: `validations/base-signer-safe-b.json`

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
