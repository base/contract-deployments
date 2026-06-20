# Update Sepolia proposer key

Status: ready to execute

## Objective

We are updating proposer address for sepolia to a key that is managed by the internal key management service.

This runbook implements scripts which allow system owner to execute:
1. `UpdateProposer` -- Upgrade `DisputeGameFactory` to have the new `PermissionedDisputeGame`.
2. `RollbackProposer` -- Rollback the `DisputeGame` upgrade.

The values we are sending are statically defined in the `.env`.

## Approving the Update transaction

### 1. Update repo and move to the appropriate folder:
```
cd contract-deployments
git pull
cd sepolia/2024-09-11-update-proposer
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
make sign-update-proposer
```

Once you run the `make sign...` command successfully, you will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and then we'll extract the domain hash and
message hash to approve on your Ledger then verify completion:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.


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

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x0fe884546476dDd290eC46318785046ef68a0BA9`. We should see the nonce increment from 5 to 6:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000007
After: 0x00000000000000000000000000000000000000000000000000000000000000008
```

2. Verify the new `PermissionedDisputeGame` is appropriately updated under "Proxy" at address `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`.

```
Key: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
Before: 0x000000000000000000000000ccefe451048eaa7df8d0d709be3aa30d565694d2
After: 0x000000000000000000000000<NEW PERMISSIONED GAME ADDRESS>
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
make sign-update-proposer
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
make sign-rollback-proposer
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

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x0fe884546476dDd290eC46318785046ef68a0BA9`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000008
After: 0x00000000000000000000000000000000000000000000000000000000000000009
```

2. Verify the new `PermissionedDisputeGame` is appropriately updated under "Proxy" at address `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`.

```
Key: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
Before: 0x000000000000000000000000<NEW PERMISSIONED GAME ADDRESS>
After: 0x000000000000000000000000ccefe451048eaa7df8d0d709be3aa30d565694d2
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
make sign-rollback-proposer
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

## Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `make execute`

> [!IMPORTANT] IN THE EVENT WE NEED TO PERFORM ROLLBACK
> Repeat the above, but replace the signatures with the signed
> rollback signatures collected, the call `make execute-rollback`