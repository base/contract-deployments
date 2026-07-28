# Set Jovian Parameters on Base Mainnet

Status: [EXECUTED](https://etherscan.io/tx/0x664cd26ba172aa2613704beeec6f8333b09bceecd8aa4fa24e48d8f3b14bcff1)

## Description

This task sets the Jovian hardfork parameters on Base Mainnet's SystemConfig contract. The parameters being set are:

- `setDAFootprintGasScalar(312)` - Sets the data availability footprint gas scalar
- `setMinBaseFee(200000)` - Sets the minimum base fee

These parameters activate with the Jovian hardfork and affect data availability fee calculations and base fee management on the L2.

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
