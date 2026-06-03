# Update Gas Limit, Elasticity & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: TODO[READY TO SIGN|DONE]

## Description

We are updating the gas limit, elasticity, and DA footprint gas scalar to improve TPS and reduce gas fees.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to our new limit of TODO gas, TODO elasticity, and TODO DA footprint gas scalar if invoked as part of the "upgrade" process, or revert to the old limit of TODO gas, TODO elasticity, and TODO DA footprint gas scalar if invoked as part of the "rollback" process.

### DA Footprint Gas Scalar

Calculate the DA footprint gas scalar from the DA limits runbook:

`go/base-da-config`

`make da-scalar TARGET_BLOB_COUNT=<value>` is the source of truth for the standard soft-cap policy. Since BPO2, Base has used a DA soft-cap blob count of 21, passed as `TARGET_BLOB_COUNT=21`, to allow the chain to use all L1 DA before raising the L2 base fee. Do not read this as Ethereum's target blob count; it is the blob-count input to Base's DA footprint scalar calculation.

Record the inputs used for this task:

Use the target network's `op_batcher_throttle_block_size_upper_limit` Config Service value for the builder hard cap row.

- Mainnet: `https://config.cbhq.net/web3-shared-prod/protocols/base-mainnet-batcherproposer-k8s?q=op_batcher_throttle_block_size_upper_limit`
- Sepolia: `https://config.cbhq.net/web3-shared-prod/protocols/base-sepolia-batcherproposer-k8s?q=op_batcher_throttle_block_size_upper_limit`
- Zeronet: `https://config.cbhq.net/web3-shared-dev/protocols/base-zeronet-batcherproposer-k8s?q=op_batcher_throttle_block_size_upper_limit`

| Field | Value |
|-------|-------|
| Gas limit | TODO |
| Elasticity | TODO |
| DA soft-cap blob count (`TARGET_BLOB_COUNT`) | TODO |
| Calculated scalar | TODO |
| Implied soft cap | TODO estimated DA bytes per L2 block |
| Builder hard cap | TODO estimated DA bytes per L2 block |

The values we are sending are statically defined in the `.env` file.

> [!IMPORTANT] We have two transactions to sign. Please follow
> the flow for both "Approving the Update transaction" and
> "Approving the Rollback transaction". Hopefully we only need
> the former, but will have the latter available if needed.

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
