# Mainnet OP Stack Separation

Status: READY TO SIGN

## Description

This task executes our migration away from the shared Superchain configuration to a Base-owned configuration. Each signer profile must produce multiple signatures, so you will repeat the signing steps in the signer tool for each part until all parts are complete.

The number of signatures required per signer profile:

| Signer Profile             | Parts        |
| -------------------------- | ------------ |
| Coinbase Signer            | 6 (part 1–6) |
| Security Council Signer    | 4 (part 1–4) |
| Optimism Signer            | 1            |
| Optimism OP Mainnet Signer | 1            |

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
- Complete the signature for the current part (e.g., part 1).
- Repeat steps 2–3 for each subsequent part (part 2, part 3, … part N) until all parts have been signed.
- After all parts are complete, close the signer tool with `Ctrl + C`.

#### 4. Send signatures to facilitator

Copy the signature outputs for all parts and send them to the designated facilitator via the agreed communication channel. The facilitator will collect all signatures and execute the transactions.

For facilitator instructions, see [FACILITATORS.md](./FACILITATORS.md).
