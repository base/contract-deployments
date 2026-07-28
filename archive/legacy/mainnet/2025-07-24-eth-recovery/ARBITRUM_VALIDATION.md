# Arbitrum ETH Recovery

## Approving the Recovery transaction

### 1. Update repo and move to the appropriate folder:

```
cd contract-deployments
git pull
cd mainnet/2025-07-24-eth-recovery
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

#### Arbitrum

```shell
make sign-arb
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

1. Verify that the nonce is incremented for the Incident Multisig under the "GnosisSafeProxy" at address `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`. We should see the nonce increment from 65 to 66:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000041
After: 0x0000000000000000000000000000000000000000000000000000000000000042
```

2. Verify that the delayed message count incremented and delayed inbox account was added in the "TransparentUpgradeableProxy" at address`0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a`. Because this is the arbitrum bridge contract that is in public use
   the exact changes may be different depending on when you run the script.
   Typically Key `0x0000000000000000000000000000000000000000000000000000000000000006` should be incremented by one and a new
   entry should be added to the delayed inbox (Key is a random hash and the change should be from `0` to some hash).

Example delayed message count increment

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000006
Before: 0x00000000000000000000000000000000000000000000000000000000001f7896
After: 0x00000000000000000000000000000000000000000000000000000000001f7897
```

Example entry

```
Key: 0xf652222313e28459528d920b65115c16c04f3efc82aaedc97be59f3f379b85d5
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0xa75a3a7db6a5b6a4458a86058d0baeb45ca7bf04255214eb0bc849ce37d14627
```

3. Verify that the signer address nonce incremented by 1

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

```shell
make sign-arb
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
