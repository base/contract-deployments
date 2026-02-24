# Update SystemConfig Parameters on Base Sepolia Alpha

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x9a0c01b65b217361cd4dcd2106bd97895d301c2a16f601cc63a2d3486403df2f)

## Description

This task brings Base Sepolia Alpha's SystemConfig parameters to parity with Base Mainnet by updating:

| Parameter | From (Sepolia Alpha) | To (Mainnet parity) |
|-----------|----------------|---------------------|
| Gas Limit | 60,000,000 | 200,000,000 |
| EIP-1559 Elasticity | 2 | 6 |
| EIP-1559 Denominator | 250 | 125 |

This runbook invokes the `UpdateSystemConfigParamsScript` defined in the [base/contracts](https://github.com/base/contracts) repository. The values we are sending are statically defined in the `.env` file.

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
After completion, the signer tool can be closed by using Ctrl + C.

### 4. Send signature to facilitator

## Prep (maintainers)

```bash
cd contract-deployments
git pull
cd sepolia-alpha/2026-02-23-update-system-config-params
make deps
make gen-validation
```

## Execute (facilitator)

1. Collect signatures from all signers and export: `export SIGNATURES="0x[sig1][sig2]..."`.
2. Run: `make execute`
