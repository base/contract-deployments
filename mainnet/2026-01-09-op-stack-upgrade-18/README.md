# OP Stack Upgrade 18

Status: [EXECUTED](https://etherscan.io/tx/0x7407256ae44170125b2d82c71f0d03cb6ade3c2268e8cd33dcb07fe259fbfd0b)

## Transactions

- Base-Nested Council Approval: [`0xc4aaa6ca4d55dca8225a176d1e0f728e0e8ff4dfd6505923bbe8a92b8745ded9`](https://etherscan.io/tx/0xc4aaa6ca4d55dca8225a176d1e0f728e0e8ff4dfd6505923bbe8a92b8745ded9) (artefacts: [run-1770741422696.json](./records/ExecuteOPCM.s.sol/1/run-1770741422696.json))
- Base-Nested Operations Approval: [`0xfad454b046dd6b7734c6da8e3f1db10a29c03223c20a1fe784f6d038fbc1f6e3`](https://etherscan.io/tx/0xfad454b046dd6b7734c6da8e3f1db10a29c03223c20a1fe784f6d038fbc1f6e3) (artefacts: [run-1770741733158.json](./records/ExecuteOPCM.s.sol/1/run-1770741733158.json))
- Base-Nested Approval: [`0x4f4a7e602287115f35b5a2820a511f27d5492145d03ce337a58e89b3b122edb0`](https://etherscan.io/tx/0x4f4a7e602287115f35b5a2820a511f27d5492145d03ce337a58e89b3b122edb0) (artefacts: [run-1770742081453.json](./records/ExecuteOPCM.s.sol/1/run-1770742081453.json))
- Unnested Optimism Foundation Operations Approval: [`0xe1be61b9fa98f63672847b0c86a988665b6a33ffaadfece6e7becf435a556a26`](https://etherscan.io/tx/0xe1be61b9fa98f63672847b0c86a988665b6a33ffaadfece6e7becf435a556a26)
- Execution Transaction: [`0x7407256ae44170125b2d82c71f0d03cb6ade3c2268e8cd33dcb07fe259fbfd0b`](https://etherscan.io/tx/0x7407256ae44170125b2d82c71f0d03cb6ade3c2268e8cd33dcb07fe259fbfd0b) (artefacts: [run-1770742201070.json](./records/ExecuteOPCM.s.sol/1/run-1770742201070.json))

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

### 2. Run the signing tool

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Be sure to select the correct task user from the list of available users to sign.
After completion, the signer tool can be closed by using Ctrl + c

### 4. Send signature to facilitator
