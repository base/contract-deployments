# Transfer SystemConfig Ownership

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xd7279a1f08275f7c9cd77b555b27a920b0a3f5dfd0c91dc059a164457d7a7254)

## Executed Transactions

- [Coinbase Approval](https://sepolia.etherscan.io/tx/0xdd7e0e60d1dc1de798d025ed0e946678cebe7d07920c2fd88d7a3aa3d3ea036d) ([artefact](./records/TransferSystemConfigOwnership.s.sol/11155111/run-1765915333831.json))
- [(Mock) Base Security Council Approval](https://sepolia.etherscan.io/tx/0xaf5ea1c6e95d0ea8ea4b1232e436c24f2871eef07fc3ea778da49475050397ff) ([artefact](./records/TransferSystemConfigOwnership.s.sol/11155111/run-1765915416897.json))
- [Coinbase Facilitator Approval](https://sepolia.etherscan.io/tx/0x2aa48dccd2a9854c6150bf3a1608eb433eb31dac250582a918e7b0187f253f0c) ([artefact](./records/TransferSystemConfigOwnership.s.sol/11155111/run-1765915501219.json))
- [(Mock) Optimism Approval](https://sepolia.etherscan.io/tx/0x22702afc8d60d3c3605dd2fb72b0860bb377dee23b1707c9d6a25a2e3ca0af2e) ([artefact](./records/TransferSystemConfigOwnership.s.sol/11155111/run-1765921561047.json))
- [Execution](https://sepolia.etherscan.io/tx/0xd7279a1f08275f7c9cd77b555b27a920b0a3f5dfd0c91dc059a164457d7a7254) ([artefact](./records/TransferSystemConfigOwnership.s.sol/11155111/run-1765921633335.json))

## Description

This task transfers ownership of the Sepolia `SystemConfig` to the incident multisig.

The SystemConfig (`0xf272670eb55e895584501d564AfEB048bEd26194`) is currently owned by `0x0fe884546476dDd290eC46318785046ef68a0BA9` which has a double-nested ownership structure. On Mainnet, this ownership is just the incident multisig directly, which results in inconsistent task structures between Sepolia and Mainnet. This is solved in this task by calling `transferOwnership` to set the new owner to `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`.

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
Sign for the two profiles (both "Direct" and "Nested") and save the two resulting signatures.
After completion, the signer tool can be closed by using Ctrl + C.

### 4. Send both signatures to the facilitator
