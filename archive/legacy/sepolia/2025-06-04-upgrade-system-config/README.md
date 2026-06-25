# Upgrade System Config

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x2aa195db4b41a6051db275bd80160c9c361caf0ee617a7c695398789182dc850)

## Description

This task contains two scripts:
1. `DeploySystemConfigScript` - This script deploys the new system config implementation.
2. `UpgradeSystemConfigScript` - This script performs the upgrade to the new implementation deployed in the previous step.

NOTE: Signers should not care about the `DeploySystemConfigScript` script as it will be ran before hand by the facilitator.
The rest of this document will focus on using the `UpgradeSystemConfigScript` script.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-06-04-upgrade-system-config
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate, Validate, and Sign

#### 3.1. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following command:

For Optimism signers:
```bash
make sign-op
```

For Base signers:
```bash
make sign-base-nested
```

For Base Security Council signers:
```bash
make sign-base-sc
```

For each run, you will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and extract the domain hash and
message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

##### 3.1.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is `Sepolia`.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).

##### 3.1.2. Validate correctness of the state diff.

Now click on the "State" tab, and refer to the validations instructions for the transaction you are signing:

- For Optimism signers: [validations instructions](./validations/OP_VALIDATION.md)
- For Base signers: [validations instructions](./validations/BASE_NESTED_VALIDATION.md)
- For Base Security Council signers: [validations instructions](./validations/BASE_SC_VALIDATION.md)

Once complete return to this document to complete the signing.

### 4. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the
`GnosisSafe.checkSignatures` call. This call's `data` parameter
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
