# Upgrade Contracts using OP Contracts Manager

Status: PENDING

## Description

This task contains two scripts. One for deploying new versions of the `FaultDisputeGame` and `PermissionedDisputeGame` contracts, and one for updating the `DisputeGameFactory` contract to reference the new dispute game contracts.

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

Be sure to select the correct task user from the list of available users to sign (**not** the "rollback" user).

### 4. Send signature to facilitator
