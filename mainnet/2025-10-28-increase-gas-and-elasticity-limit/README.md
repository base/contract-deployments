# Update Gas Limit & Elasticity in L1 `SystemConfig`

Status: READY TO SIGN

## Description

We are updating the gas limit and elasticity to improve TPS and reduce gas fees.

This runbook invokes the following script which allows our signers to sign the same call with two different sets of parameters for our Incident Multisig, defined in the [base-org/contracts](https://github.com/base/contracts) repository:

`IncreaseEip1559ElasticityAndIncreaseGasLimitScript` -- This script will update the gas limit to our new limit of 200M gas and 4 elasticity if invoked as part of the "upgrade" process, or revert to the old limit of 150M gas and 3 elasticity if invoked as part of the "rollback" process.

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

Be sure to select the correct task user from the list of available users to sign (**not** the "rollback" user).

### 4. Send signature to facilitator

## Approving the Rollback transaction

Complete the above steps for `Approving the Update transaction` before continuing below.

### 1. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

```shell
make sign-rollback
```

Once you run the make sign command successfully, you will see a "Simulation link" from the output. Once again paste this URL in your browser and click "Simulate Transaction".

We will be performing 3 validations and then we'll extract the domain hash and
message hash to approve on your Ledger then verify completion:

1. Validate integrity of the simulation and that it completed successfully.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

#### 2. Validate integrity of the simulation and that it completed successfully.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account or a valid signer address (from the Safe multi-sig).
4. "Success" with a green check mark

#### 3. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x000000000000000000000000000000000000000000000000000000000000005d
After: 0x000000000000000000000000000000000000000000000000000000000000005e
```

2. Verify that **NO** gas limit value or elasticity value is updated and thus no changes are shown for a "Proxy" address at `0x73a79fab69143498ed3712e519a88a918e1f4072`. This is because the values would change back to the exact same values that are currently set, therefore no state changes should be displayed for this.

#### 4. Validate and extract domain hash and message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the
`GnosisSafe.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up
in your Ledger.

Here is an example screenshot. Note that the value will be
different for each signer:

![Screenshot 2024-03-07 at 5 49 32 PM](https://github.com/base-org/contract-deployments/assets/84420280/b6b5817f-0d05-4862-b16a-4f7f5f18f036)

It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones
displayed on the Ledger screen at signing. Also, ensure that it matches the following:

```
Domain hash: 0xf3474c66ee08325b410c3f442c878d01ec97dd55a415a307e9d7d2ea24336289
Message hash: 0x5d50efea16ce96c189a49bcb87e208506bb4c612a5ef66c81dd5790f01ef7089
```

### 5. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

```shell
make sign-rollback
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. On your Ledger screen.
2. In the Tenderly simulation. You should use the same Tenderly
   simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

There is no need to verify anything printed in the console. There is
no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 6. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!
