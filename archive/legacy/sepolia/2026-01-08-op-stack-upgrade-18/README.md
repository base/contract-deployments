# OP Stack Upgrade 18

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x357c790c6665a036dd658cfe5b22b8a46b084da8473e9a145f7c1cc96abe8196)

## Description

Upgrade 18 is a proposed network upgrade for OP Stack chains, which introduces **cannon+kona fault proof support** (including an optional switch to Kona proofs as the respected game type) and introduces **Custom Gas Token v2 (CGT v2)** for chains that want to use a non-ETH native fee currency.

Upgrade 18 is purely a smart contract upgrade. There are no hardforks activating during this upgrade.

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
