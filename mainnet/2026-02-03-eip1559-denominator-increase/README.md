# Increase EIP-1559 Denominator in L1 `SystemConfig`

Status: [EXECUTED](https://etherscan.io/tx/0x30bb34595b1536556112591bfd26b9b24096dbfb37d59cc13515101a5f8b4de5)

## Description

We are increaseing the EIP-1559 Denominator to reduce the maximum rate of change for the base fee, and thus limit overall fee volatility.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559Denominator` -- This script will update the EIP-1559 denominator to 125 if invoked as part of the "upgrade" process, or revert to the old denominator of 50 if invoked as part of the "rollback" process.

The values we are sending are statically defined in the `.env` file.

> [!IMPORTANT]
>
> We have two transactions to sign. Please follow
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

### 2. Run the signing tool

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Be sure to select the correct task from the list of available tasks to sign (**not** the "Base Signer Rollback" task). Copy the resulting signature and save it.

### 4. Rollback signing

Now, click on the "Base Signer" selection and switch over to the rollback task (called "Base Signer Rollback"). Copy the resulting signature and save it.

### 5. Send signatures to facilitator

Send the two signatures to the facilitator and make sure to clearly note which one is the primary one and which one is the rollback.

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
