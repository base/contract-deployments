# Activate Multiproof

Status: DRAFT

## Description

This task activates multiproof on `zeronet`.

It includes:
1. a facilitator-only deploy script that writes `addresses.json`
2. a signed upgrade script for the L1 cutover

This task does not include the proposer-side follow-up steps after the upgrade.

## Procedure

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

If you see a version output from the above command, you can move on. Otherwise, install node:

```bash
brew install node
```

### 3. Update repo and install deps

```bash
cd contract-deployments
git pull
cd zeronet/YYYY-MM-DD-activate-multiproof
make deps
```

### 4. Fill in env files

Before running the task, fill in:

- [`zeronet/.env`](../.env)
- [`zeronet/YYYY-MM-DD-activate-multiproof/.env`](.env)

### 5. Run the deploy step

```bash
make deploy
```

This generates `addresses.json` with the deployed Nitro and multiproof contract addresses, which is then used by the upgrade script.

## Approve the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

```bash
make sign-task
```

### 3. Generate the validation

```bash
cd zeronet/YYYY-MM-DD-activate-multiproof
make gen-validation-upgrade
```

This generates one validation file for `CB_SIGNER_SAFE_ADDR` and one for `CB_SC_SAFE_ADDR`.

### 4. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

### 5. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel. The facilitator will collect all signatures and execute the transaction.
