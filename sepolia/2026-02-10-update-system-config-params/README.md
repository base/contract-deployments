# Update SystemConfig Parameters on Base Sepolia

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x448c6318e1f6fb2f247944d4377a977158f07a56eb84a19362ecfeca770e3a06) ([artefact](./records/UpdateSystemConfigParams.s.sol/11155111/run-1770758365511.json))

## Description

This task brings Base Sepolia's SystemConfig parameters to parity with Base Mainnet by updating:

| Parameter | From (Sepolia) | To (Mainnet parity) |
|-----------|----------------|---------------------|
| Gas Limit | 60,000,000 | 375,000,000 |
| EIP-1559 Elasticity | 4 | 6 |
| EIP-1559 Denominator | 50 | 125 |
| Min Base Fee | 200,000 wei | 2,000,000 wei |
| DA Footprint Gas Scalar | 312 | 139 |

The DA footprint gas scalar targets 14 blobs per L1 block, matching mainnet:

```
da_footprint_gas_scalar = gas_limit / (elasticity * target_blob_count * 32,000)
                        = 375,000,000 / (6 * 14 * 32,000) = 139
```

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
cd sepolia/2026-02-10-update-system-config-params
make deps
make gen-validation
```

## Execute (facilitator)

1. Collect signatures from all signers and export: `export SIGNATURES="0x[sig1][sig2]..."`.
2. Run: `make execute`
