# Switch to Permissioned Games

Status: READY TO SIGN

## Description

Switches Base to Permissioned Fault Dispute Games and retires existing games.

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

## Sign Task

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

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.

