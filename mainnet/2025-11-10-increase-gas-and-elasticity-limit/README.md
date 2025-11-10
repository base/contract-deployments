# Update Mainnet Gas Params

Status: READY TO SIGN

## Description

We are updating the gas limit to **300 MGas / block** and elasticity to **5** improve TPS and reduce gas fees.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig:

`UpdateGasParams` -- This script will update the gas limit to our new limit of 300M gas and 5 elasticity if invoked as part of the "upgrade" process, or revert to the old limit of 250M gas and 4 elasticity if invoked as part of the "rollback" process.

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

> [!IMPORTANT] Please run through the signing process twice. Once for "Base Signer" and once for "Base Signer Rollback"

### 4. After signing, you can end the signer tool process with Ctrl + C
