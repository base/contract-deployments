# Update Sepolia Incident Multisig Signers

Status: [SAFE A EXECUTED](https://sepolia.etherscan.io/tx/0xadffced4438bd307fe2d61cfb212e46c3f07b73ffdc833a094b2b4e21ad6cd34) ([artefact](./records/UpdateSigners.s.sol/11155111/run-1763579592746.json)) and [SAFE B EXECUTED](https://sepolia.etherscan.io/tx/0x2aa63f880ca4cf814a71197a3fa9059ff36b124cabf085a3e8e76e40b9e6c556) ([artefact](./records/UpdateSigners.s.sol/11155111/run-1763579822181.json))

Safe A (3-of-14): [0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f](https://sepolia.etherscan.io/address/0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f)  
Safe B (1-of-14): [0x6AF0674791925f767060Dd52f7fB20984E8639d8](https://sepolia.etherscan.io/address/0x6AF0674791925f767060Dd52f7fB20984E8639d8)

## Description

We are updating both Sepolia Incident Multisig Safes to reflect the current Base Chain Eng roster. The signer additions and removals are listed in [OwnerDiff.json](./OwnerDiff.json) and apply to both safes. Safe A keeps its 3-of-14 threshold, while Safe B mirrors the same owners with a 1-of-14 threshold.

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

### 2. Install Node.js if needed

First, check if you have node installed:

```bash
node --version
```

If you see a version output at or above `v18.18`, you can move on. Otherwise, install (or update) node:

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

Then select the Safe for which you would like to sign. Typically this will be Safe A, since Save B only requires a single signature and can thus usually be provided by the task facilitator themselves.
   - Safe A → `validations/base-signer.json`
   - Safe B → `validations/base-signer-safe-b.json`

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
