# Update Min Base Fee & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: [EXECUTED](https://etherscan.io/tx/0x3be4d20dad2aa0b98938e806619a2948f7f6ac74d63181f74aa169c8ea4afc35)

## Description

We are updating the min base fee and DA footprint gas scalar on Base mainnet.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base/contracts](https://github.com/base/contracts) repository:

`SetMinBaseFeeAndDAFootprintScript` -- This script will update the min base fee from 500,000 wei to 1,000,000 wei (2x increase) and the DA footprint gas scalar from 325 to 139 (targeting 14 blobs) if invoked as part of the "upgrade" process, or revert to the old values if invoked as part of the "rollback" process.

## Parameters

| Parameter | From | To |
|-----------|------|----|
| minBaseFee | 500,000 wei | 1,000,000 wei |
| daFootprintGasScalar | 325 | 139 |

### DA Footprint Gas Scalar Formula

We typically set the DA footprint gas scalar to cause base fees to rise if and only if the DA usage exceeds the L1 target blob throughput. (Below that level of DA usage, the normal base fee rules apply.) We use the following formula:

```
da_footprint_gas_scalar = gas_limit / (elasticity * l2_block_time * l1_target_throughput * estimation_ratio)
```

Where:
- `gas_limit` = L2 gas limit per block
- `elasticity` = EIP-1559 elasticity multiplier
- `l2_block_time` = 2 seconds
- `l1_target_throughput = (target_blob_count * 128,000 bytes/blob) / 12 sec/block`
- `target_blob_count` = target number of blobs per L1 block
- `estimation_ratio` = 1.5 to account for differences between compression estimates and actual usage

This simplifies to:

```
da_footprint_gas_scalar = gas_limit / (elasticity * target_blob_count * 32,000)
```

With current gas_limit = 375,000,000, elasticity = 6, and target_blob_count = 14:
```
da_footprint_gas_scalar = 375,000,000 / (6 * 14 * 32,000) = 139.51 ≈ 139 (floored)
```

You can verify with `make da-scalar GAS_LIMIT=375000000 ELASTICITY=6 TARGET_BLOB_COUNT=14`.

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

## Prep (maintainers)

```bash
cd contract-deployments
git pull
cd mainnet/2026-01-20-update-basefee-da-footprint
make deps
make gen-validation
make gen-validation-rollback
```

## Execute

1. Collect signatures from all signers and export: `export SIGNATURES="0x[sig1][sig2]..."`.
2. Upgrade: `make execute`
3. Rollback (only if needed): `make execute-rollback`
