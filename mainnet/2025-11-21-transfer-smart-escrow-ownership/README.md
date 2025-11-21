# Initiate SmartEscrow Ownership Transfer

Status: READY TO SIGN

## Description

We wish to update the owner of our [SmartEscrow](https://optimistic.etherscan.io/address/0xb3c2f9fc2727078ec3a2255410e83ba5b62c5b5f) contract on OP Mainnet to be the aliased address of our L1 [ProxyAdminOwner](https://etherscan.io/address/0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c). The `SmartEscrow` contract inherits access control mechanisms from OpenZeppelin's `AccessControlDefaultAdminRules`, which requires an ownership transfer to be invoked in two separate steps:

1. Initiate the transfer to a new owner from the existing owner
2. Accept the transfer from the pending new owner after a configured delay

This task represents the initiation step. A subsequent task will be written for ownership acceptance after a 5 day delay.

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