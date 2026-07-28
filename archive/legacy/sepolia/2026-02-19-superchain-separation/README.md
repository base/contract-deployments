# Sepolia OP Stack Separation

Status: EXECUTED

[Step 1](https://sepolia.etherscan.io/tx/0x172e6bef6e1cf87fc13739f9b8ca56ac0801aeec59fa04420aaa6457bcdc27a3)
[Step 2](https://sepolia.etherscan.io/tx/0x60c05a9ee8f30a8c1fc0f739ae9be01e755045c976ae0b78ee2c3f1ba9eeaed8)
[Step 3](https://sepolia.etherscan.io/tx/0x3c056f12475a39854ef1b525fc61e27237b79c7ba4120b07ef327c9ec1c8391f)

## Description

This task executes our migration away from the shared Superchain configuration to a Base-owned configuration.

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

For facilitator instructions, see [FACILITATORS.md](./FACILITATORS.md).
