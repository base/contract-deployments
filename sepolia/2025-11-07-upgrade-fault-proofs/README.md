# U17 Jovian Upgrade

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x248f85399e2a23687bd9d1440b51d9677a94ff763827abcad5a2a4b457c70590)

## Description

The Jovian hardfork is a proposed network upgrade for OP Stack chains, which brings several improvements to the way rollup fees are calculated as well as performing a maintenance update to the fault proof virtual machine. [More Details](https://docs.optimism.io/notices/upgrade-17).

This script executes the `upgrade` function of the OP Contracts Manager to upgrade all relevant contracts.

## Procedure

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

## Approving the Update transaction

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

Be sure to select the correct task user from the list of available users to sign.
After completion, the signer tool can be closed by using Ctrl + c

### 4. Send signature to facilitator
