# Update Mainnet Incident Multisig Signers

Status: READY TO SIGN

## Description

We wish to update the owners of our [Incident Multisig](https://etherscan.io/address/0x14536667Cd30e52C0b458BaACcB9faDA7046E056) on Mainnet to be consistent with the current state of our Base Chain Eng team. This involves removing signers that are no longer closely involved with the team, and adding new team members as signers. The exact signer changes are outlined in the [OwnerDiff.json](./OwnerDiff.json) file.

## Setup

### 1. Update foundry

```
foundryup
```

### 2. Install Node.js if needed

Check if you have node installed

```bash
node --version
```

If you do not see a version above or if it is older than v18.18, install

```bash
brew install node
```

## Sign Task

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

### 4. After signing, you can end the signer tool process with Ctrl + C
