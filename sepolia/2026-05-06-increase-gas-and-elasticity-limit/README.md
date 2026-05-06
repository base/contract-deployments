# Update Gas Limit, EIP-1559 Params & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: READY TO SIGN

> [!NOTE] **Prerequisite:** This task requires the SystemConfig `maximumGasLimit` to be raised
> from 500M to 2B first. See `sepolia/2026-05-06-increase-max-gas-limit` (separate PR).

## Description

We are updating the gas limit, EIP-1559 elasticity, EIP-1559 denominator, and DA footprint gas scalar to increase burst capacity while preserving the current gas target.

The intended gas/elasticity shape is to preserve the current gas target while increasing burst capacity:

```
current:  gas_limit = 400,000,000,   elasticity = 5  -> gas_target = 80,000,000
proposed: gas_limit = 1,200,000,000, elasticity = 15 -> gas_target = 80,000,000
```

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to 1,200,000,000, elasticity to 15, denominator to 100, and DA footprint gas scalar to 446 if invoked as part of the "upgrade" process, or revert to the old limit of 400,000,000 gas, elasticity of 5, denominator of 100, and DA footprint gas scalar of 148 if invoked as part of the "rollback" process.

### DA Footprint Gas Scalar

The DA footprint gas scalar is set to 446, anchored to the L1 blob limit (21 blobs):

```
da_footprint_gas_scalar = gas_limit / (blob_limit * blob_size)
                        = 1,200,000,000 / (21 * 128,000)
                        = 446
```

**Rationale:** This threshold is appropriate given current macro conditions where there is negligible non-Base blob usage, meaning Base can safely consume roughly the entire blob limit without accruing a DA backlog. The DA footprint is almost always overestimated (computed from independently compressed transaction payloads rather than full-block compression), so anchoring to the target would risk raising base fees prematurely before blob target throughput is actually reached.

Additionally, the practical DA ceiling (~3MB `MAX_DA_BYTES_PER_BLOCK` in batcher config) independently validates this range: `1,200,000,000 / 3,000,000 ≈ 400`, which converges with the blob-limit formula.

Note: DA footprint monitoring should confirm these parameters remain appropriate, particularly as blob market conditions evolve.

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
