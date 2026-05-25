# Update Gas Limit, EIP-1559 Params & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: READY TO SIGN

> [!NOTE] **Prerequisite:** This task requires the SystemConfig `maximumGasLimit` to be raised
> from 500M to 2B first. A separate task (analogous to `sepolia/2026-05-06-increase-max-gas-limit`)
> will be created to handle that upgrade.

## Description

We are updating the gas limit, EIP-1559 elasticity, EIP-1559 denominator, and DA footprint gas
scalar on Zeronet to bring it to parity with the Sepolia configuration set by
`sepolia/2026-05-06-increase-gas-and-elasticity-limit`.

```
current:  gas_limit = 25,000,000,    elasticity = 6  (default) -> gas_target = 4,166,666
proposed: gas_limit = 1,200,000,000, elasticity = 15           -> gas_target = 80,000,000
```

This runbook invokes the following script which allows our signers to sign the same call with two
different sets of parameters for our Incident Multisig, defined in the
[base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to
1,200,000,000, elasticity to 15, denominator to 100, and DA footprint gas scalar to 119 if invoked
as part of the "upgrade" process, or revert to the prior limit of 25,000,000 gas, elasticity of 0,
denominator of 0, and DA footprint gas scalar of 0 if invoked as part of the "rollback" process.

### Note on the FROM values

The L1 `SystemConfig` storage on Zeronet has never had its EIP-1559 params or DA footprint scalar
explicitly written, so the raw `eip1559Elasticity()`, `eip1559Denominator()`, and
`daFootprintGasScalar()` getters all return 0. The chain currently operates with the rollup-config
defaults (denominator=250, elasticity=6, daFootprintGasScalar=400), which are surfaced in L2 block
`extraData` and on the L1Block predeploy. The script's pre-checks read from the raw SystemConfig
getters, so the `FROM_*` values in `.env` are set to match that raw storage (0 for the three
defaulted fields, 25,000,000 for `gasLimit`).

### DA Footprint Gas Scalar

The DA footprint gas scalar is set to 119, computed via the `make da-scalar` helper:

```
da_footprint_gas_scalar = TO_GAS_LIMIT / (TO_ELASTICITY * TARGET_BLOB_COUNT * 32,000)
                        = 1,200,000,000 / (15 * 21 * 32,000)
                        = 119
```

This targets a soft cap of 21 blobs per L1 block (~672,000 estimated bytes per L2 block).

The DA footprint scalar controls both:

- a soft cap, where DA footprint begins increasing the EIP-1559 base fee
- a hard cap, where DA footprint prevents further block inclusion

```
soft cap = (gas_limit / elasticity) / scalar
hard cap = gas_limit / scalar
```

With the new parameters (gas_limit=1.2B, elasticity=15, scalar=119):

- soft cap: ~672 KB per L2 block (~21 blobs per L1 block target)
- hard cap: ~10.1 MB per L2 block

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
