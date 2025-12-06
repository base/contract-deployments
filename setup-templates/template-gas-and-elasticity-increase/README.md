# Update Gas Limit, Elasticity & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: TODO[READY TO SIGN|DONE]

## Description

We are updating the gas limit, elasticity, and DA footprint gas scalar to improve TPS and reduce gas fees.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to our new limit of TODO gas, TODO elasticity, and TODO DA footprint gas scalar if invoked as part of the "upgrade" process, or revert to the old limit of TODO gas, TODO elasticity, and TODO DA footprint gas scalar if invoked as part of the "rollback" process.

### DA Footprint Gas Scalar Formula

The DA footprint gas scalar is calculated from the gas limit and elasticity:

```
da_footprint_gas_scalar = gas_limit / (elasticity * l2_block_time * l1_target_throughput * estimation_ratio)
```

Where:
- `gas_limit` = L2 gas limit per block
- `elasticity` = EIP-1559 elasticity multiplier
- `l2_block_time` = 2 seconds
- `l1_target_throughput = (target_blob_count * 128,000 bytes/blob) / 12 sec/block`
- `target_blob_count` = target number of blobs per L1 block
- `estimation_ratio` = 1.5

This simplifies to:

```
da_footprint_gas_scalar = gas_limit / (elasticity * target_blob_count * 32,000)
```

Example with gas_limit = 120,000,000, elasticity = 2, and target_blob_count = 6:
```
da_footprint_gas_scalar = 120,000,000 / (2 * 6 * 32,000) = 312.5 ≈ 312
```

The values we are sending are statically defined in the `.env` file.

> [!IMPORTANT] We have two transactions to sign. Please follow
> the flow for both "Approving the Update transaction" and
> "Approving the Rollback transaction". Hopefully we only need
> the former, but will have the latter available if needed.

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

Be sure to select the correct task from the list of available tasks to sign (**not** the "Base Signer Rollback" task). Copy the resulting signature and save it.

### 4. Rollback signing

Now, click on the "Base Signer" selection and switch over to the rollback task (called "Base Signer Rollback"). Copy the resulting signature and save it.

### 5. Send signature to facilitator

Send the two signatures to the facilitator and make sure to clearly note which one is the primary one and which one is the rollback.

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
