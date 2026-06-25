# Transfer ownership of L1 `BalanceTracker` from the CB Upgrade multisig to the CB Incident multisig 

Status: EXECUTED
https://etherscan.io/tx/0x096cdc7349e9eba3ee7f69c103adfdc6565dbe36bb523fa84169391dee6b6e58

## Objective

Transfer the ownership of the L1 `BalanceTracker` contract from the CB Upgrade multisig to the CB Incident multisig.
This allows us to be more responsive to required balance changes for our batcher, proposer, and challenger addresses.

## Approving the transaction

### 1. Update repo and move to the appropriate folder:
```
cd contract-deployments
git pull
cd mainnet/2024-07-23-transfer-owner-balance-tracker
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
make sign
```

Once you run the `make sign` command successfully, you will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 1 validation, and then we'll extract the domain hash and
message hash to approve on your Ledger then verify completion:

1. Validate the proxy admin has been updated correctly.


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

1. Verify that the nonce is incremented for the Upgrade Multisig under the "GnosisSafeProxy" at address `0x9855054731540A48b28990B63DcF4f33d8AE46A1`. We should see the nonce increment from 13 to 14:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x000000000000000000000000000000000000000000000000000000000000000d
After: 0x000000000000000000000000000000000000000000000000000000000000000e
```

2. Verify that the admin is appropriately updated under "Proxy" at address `0x23B597f33f6f2621F77DA117523Dffd634cDf4ea`.
We should see that the admin change from 0x9855054731540a48b28990b63dcf4f33d8ae46a1 to 0x14536667cd30e52c0b458baaccb9fada7046e056:

```
Key: 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
Before: 0x0000000000000000000000009855054731540a48b28990b63dcf4f33d8ae46a1
After: 0x00000000000000000000000014536667cd30e52c0b458baaccb9fada7046e056
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
make sign
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
