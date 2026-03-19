# Transfer SystemConfig Ownership

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xbecc51d4a88eda31d43327e6dea56d74f442c6090358b697fdbad0bef02fa43c)

## Description

This task transfers ownership of the Sepolia `SystemConfig` (`0xf272670eb55e895584501d564AfEB048bEd26194`) from `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f` to `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.

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

If not, install it:

```bash
brew install node
```

### 3. Update repo and install deps

```bash
cd contract-deployments
git pull
cd sepolia/2026-03-06-transfer-system-config-ownership
make deps
```

## Sign the transaction

### 1. Run the signing tool from the project root

```bash
cd contract-deployments
make sign-task
```

### 2. Open the UI at [http://localhost:3000](http://localhost:3000)

Select the correct task user from the list of available users and sign the transaction.

### 3. Send the signature to the facilitator

Facilitator execution steps are documented in `FACILITATOR.md`.
