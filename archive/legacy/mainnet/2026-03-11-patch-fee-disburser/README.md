# FeeDisburser Patch

Status: [EXECUTED](https://etherscan.io/tx/0xd156906b67b1110bc1f804367bae08d77afbd9ca65be146449d551ae9f0c5af1)

## Description

Our latest deployment of the `FeeDisburser` contract is using an interface that is incompatible with our current FeeVault deployments on Base. This patch upgrade fixes the interface.

## Procedure

### Install dependencies

#### 1. Update foundry

```bash
foundryup
```

#### 2. Install Node.js if needed

First, check if you have node installed:

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node:

```bash
brew install node
```

### Approve the transaction

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run the signing tool

```bash
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel. The facilitator will collect all signatures and execute the transaction.
