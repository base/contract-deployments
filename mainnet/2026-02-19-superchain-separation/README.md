# Mainnet OP Stack Separation

Status: READY TO SIGN

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
