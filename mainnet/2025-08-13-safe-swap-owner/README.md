# Swap Owner on Gnosis Safe

Status: PENDING

## Description

This task contains a single script that can be used to swap an owner in a Gnosis Safe. 

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
make setup-safe-management network=<network>
cd <network>/<date>safe-swap-owner
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate, Validate, and Sign

#### 3.1. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

```bash
make sign
```

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and extract the domain hash and
message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

##### 3.1.1. Validate integrity of the simulation.

Make sure you are on the "Summary" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is `<network>`.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account.

##### 3.1.2. Validate correctness of the state diff.

Now click on the "State" tab, and refer to the [State Validations](./VALIDATION.md) instructions for the transaction you are signing.
Once complete return to this document to complete the signing.

### 4. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Summary" tab, and find the
`Safe.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up
in your Ledger.

It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones
displayed on the Ledger screen at signing.

Once the validations are done, it's time to actually sign the
transaction.

> [!WARNING]
> This is the most security critical part of the playbook: make sure the
> domain hash and message hash in the following three places match:
>
> 1. On your Ledger screen.
> 2. In the terminal output.
> 3. In the Tenderly simulation. You should use the same Tenderly
>    simulation as the one you used to verify the state diffs, instead
>    of opening the new one printed in the console.
>

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```shell
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

#### 4.1. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

### [For Facilitator ONLY] How to execute

#### Execute the transaction

1. Collect outputs from all participating signers.
1. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`.
1. Run the `make execute` command as described below to execute the transaction.

For example, if the quorum is 2 and you get the following outputs:

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

Then you should run:

Coinbase facilitator:

```bash
SIGNATURES=AAAABBBB make execute
```
