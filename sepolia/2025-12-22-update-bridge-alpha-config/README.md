# Update Base Bridge Alpha Validator Config

Status: READY TO SIGN

Deployment: [EXECUTED](https://sepolia.basescan.org/tx/0x03b7f6fb2777fdd874c22994d28d56cab6c7b4462feebee967219cfd460a4186)

## Description

Upgrades the `Bridge` contract for the testnet alpha deployment of [Base Bridge](https://github.com/base/bridge).

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

If you do not see a version above or if it is older than v18.18, install

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

### 4. After signing, you can end the signer tool process with Ctrl + C
