# Update Gas Config in L1 `SystemConfig` 

Status: READY TO SIGN

## Objective

Because of the recently blob market fee dynamics, we had to pay extra priority fees in order for the blobs to be included in L1, which resulted in a net loss. Because of this, we wanted to tweak the gas scalar to do some L1 fee recovery.

We need to make changes to the Gas Config in the L1 `SystemConfig` contract. Specifically, we need to set the `_overhead` and `_scalar` values by calling `setGasConfig`. This is an access-controlled method that only the Incident Multisig can call.

This runbook implements scripts to allow our signers to sign two different calls for our Incident Multisig: 
1. `UpdateGasConfig` -- This script will update the values according to our expected new scalar values
2. `RollbackGasConfig` -- This script establishes a rollback call in the case we need to revert to old values

> [!IMPORTANT] We have two transactions to sign. Please follow 
> the flow for both "Approving the Update transaction" and 
> "Approving the Rollback transaction". Hopefully we only need
> the former, but will have the latter available if needed. 

## Approving the Update transaction

### 1. Update repo and move to the appropriate folder:
```
cd contract-deployments
git pull
cd mainnet/2024-06-25-update-gas-config
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
make sign-update-gas-config
```

Note: there have been reports of some folks seeing this error `Error creating signer: error opening ledger: hidapi: failed to open device`. A fix is in progress, but not yet merged. If you come across this, open a new terminal and run the following to resolve the issue:
```
git clone git@github.com:base-org/eip712sign.git
cd eip712sign
go install
```

Once you run the make sign command successfully, you will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and then we'll extract the domain hash and
message hash to approve on your Ledger then verify completion:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.
4. Validate that the transaction completed successfully


#### 3.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger.
4. "Success" with a green check mark 


#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000013
After: 0x0000000000000000000000000000000000000000000000000000000000000014
```

2. Verify that gas config values are appropriately updated under "Proxy" at address `0x73a79fab69143498ed3712e519a88a918e1f4072`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000066
Before: 0x010000000000000000000000000000000000000000000000000a118b0000044d
After: 0x010000000000000000000000000000000000000000000000000a118b0000058a
```

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the
`GnosisSafe.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up
in your Ledger.

Here is an example screenshot. Note that the value will be
different for each signer:

![Screenshot 2024-03-07 at 5 49 02 PM](https://github.com/base-org/contract-deployments/assets/84420280/1b7905f1-1350-4634-a804-7b4458d0ddc9)


It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones
displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
make sign-update-gas-config
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly
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

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!


## Approving the Rollback transaction

Complete the above steps for `Approving the Update transaction` before continuing below.

### 1. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.
``` shell
make sign-rollback-gas-config
```
Once you run the make sign command successfully, you will see a "Simulation link" from the output. Once again paste this URL in your browser and click "Simulate Transaction".

We will be performing 3 validations and then we'll extract the domain hash and
message hash to approve on your Ledger then verify completion:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.
4. Validate that the transaction completed successfully


#### 3.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger.
4. "Success" with a green check mark 


#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000014
After: 0x0000000000000000000000000000000000000000000000000000000000000015
```

2. Verify that gas config values are appropriately updated under "Proxy" at address `0x73a79fab69143498ed3712e519a88a918e1f4072`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000066
Before: 0x010000000000000000000000000000000000000000000000000a118b0000058a
After: 0x010000000000000000000000000000000000000000000000000a118b0000044d
```

Or under Events tab there is the `ConfigUpdate` event
```
{
"version":"0"
"updateType":1
"data":"0x0000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000a118b0000044d"
}
```


#### 3.3. Extract the domain hash and the message hash to approve.

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
displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
make sign-rollback-gas-config
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly
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

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

> [!WARNING]  
> ONLY PROCEED IF WE MUST FALLBACK TO CALLDATA

## Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `make approve-rollback-gas-config`
4. Run `make execute-rollback` to execute the transaction onchain.

