# Update Gas Limit & Elasticity in L1 `SystemConfig`

Status: TODO[READY TO SIGN|DONE]

## Description

We are updating the gas limit and elasticity to improve TPS and reduce gas fees.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to our new limit of TODO gas and TODO elasticity if invoked as part of the "upgrade" process, or revert to the old limit of TODO gas and TODO elasticity if invoked as part of the "rollback" process.

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

Be sure to select the correct task from the list of available tasks to sign (**not** the rollback task).

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.

## Approving the Rollback transaction

Complete the above steps for `Approving the Update transaction` before continuing below.

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

Be sure to select the correct task from the list of available tasks to sign (ensure it **is** the rollback task).

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
