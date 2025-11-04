# Set Jovian Parameters on Base Sepolia

Status: NOT YET EXECUTED

## Description

This task sets the Jovian hardfork parameters on Base Sepolia's SystemConfig contract. The parameters being set are:

- `setDAFootprintGasScalar(260)` - Sets the data availability footprint gas scalar
- `setMinBaseFee(5000000)` - Sets the minimum base fee

These parameters activate with the Jovian hardfork and affect data availability fee calculations and base fee management on the L2.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-11-03-set-jovian-parameters
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate, Validate, and Sign

#### 3.1. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following command:

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

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is `Sepolia`.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).

##### 3.1.2. Validate correctness of the state diff.

Now click on the "State" tab, and refer to the [VALIDATION.md](./VALIDATION.md) instructions. Once complete return to this document to complete the signing.

#### 3.2. Extract the domain hash and the message hash to approve.

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

#### 3.3. Sign the transaction

Once the validations are done, a prompt will appear on the Ledger
for you to sign a transaction. Before accepting, scroll to the screen that
shows:

```
EIP712 DOMAIN_HASH
```

It will look something like this:

```
DOMAIN_HASH
0x454a4be2...
```

Compare this hash with the domain hash you extracted earlier. If they match,
continue scrolling to the screen that shows:

```
EIP712 MESSAGE_HASH
```

It will look something like this:

```
MESSAGE_HASH
0x6f21c9af...
```

Compare this hash with the message hash you extracted earlier. If they match,
accept the transaction on your Ledger.

A `data` field will be printed in the console. **This is the signature you just created.**

### 4. Approve and Execute

Once signatures have been collected, the transaction can be approved and executed following the same validation process above.
