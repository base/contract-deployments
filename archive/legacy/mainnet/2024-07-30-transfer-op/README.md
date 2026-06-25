# Transfer OP Tokens to SmartEscrow

Status: EXECUTED
Tx hash: https://optimistic.etherscan.io/tx/0xf1278d1e3fca35113e2b411a58c69b993e1171021097afbdd6f6b02407deb0ce

## Objective

When Base launched, Optimism granted a share of OP tokens to Coinbase. The token distribution occurs onchain, and vests over a period of 6 years, with the first vesting event in July 2024. A smart contract handles the logic to make the tokens available for distribution as they vest. This smart contract (the "Smart Escrow Contract") also receives OP tokens 1 year before they vest and stores them until vesting. However, since the Smart Escrow contract was not ready upon Base launch, the existing OP tokens are being stored in a 2-of-2 multisig with CB & OP signers (similar to the multisig used for Base's upgrade keys, except on the Optimism network). 

Now that the Smart Escrow contract is live, this task moves any existing OP tokens from the 2-of-2 multisig to the Smart Escrow contract.

## Approving the transaction

### 1. Update repo and move to the appropriate folder:

```
cd contract-deployments
git pull
cd mainnet/2024-07-30-transfer-op
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
make sign-op # or make sign-cb for Coinbase signers
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

1. "Network": Check the network is Optimism Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger.
4. "Success" with a green check mark 


#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Verify that the nonce is incremented for the Nested Multisig under the "GnosisSafeProxy" at address `0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000001
After: 0x0000000000000000000000000000000000000000000000000000000000000002
```

2. And for the same contract, verify that this specific execution is approved by the other signer multisig:

```
Key (if you are an OP signer): 0xca90537b72eefaa217070da5269b8eed78462a4399c1fa107670d1a4cab3301a
Key (if you are a CB signer): 0x4e7d70e21746b3fcaf2ac086ca20325513b71ba63d976a9e3792a8921ab8d75e
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x0000000000000000000000000000000000000000000000000000000000000001
```

3. Verify that the nonce is incremented for your multisig.

If you are an OP signer - the OP Foundation Multisig should be under the "GnosisSafeProxy" at address `0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000082
After: 0x0000000000000000000000000000000000000000000000000000000000000083
```

If you are a CB signer - the Coinbase Multisig should be under the address `0x6e1dfd5c1e22a4677663a81d24c6ba03561ef0f6`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000002
After: 0x0000000000000000000000000000000000000000000000000000000000000003
```

4. Verify that the state changes for the OP ERC20 token match the expected balance updates.  Under the "Optimism ERC-20" `_balances` field, look for the following state changes:

```
0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940      42054887000000000000000000 -> 0
0xb3c2f9fc2727078ec3a2255410e83ba5b62c5b5f      0 -> 42054887000000000000000000
```
The raw state changes will look like this (if you convert the hex values to decimal you'll get the above values):

```
Key: 0x6d16b6fe5688f7b25d007e8e32e8ef55e43df772df001dd04dca46e4b074515a
Before: 0x00000000000000000000000000000000000000000022c977fe114f325b3c0000
After: 0x0000000000000000000000000000000000000000000000000000000000000000
```

```
Key: 0x9c7ffc2d159d7a0a8143e9bb815194a3d0239701011646f61c42aefd6122e68c
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x00000000000000000000000000000000000000000022c977fe114f325b3c0000
```

5. Verify that the `L1FeeVault` at `0x420000000000000000000000000000000000001a` receives the gas associated with the call:

_Note: the balance values here will not be exactly the same_
```
Balance     2523179754840340647 -> 2523179853060159772
```

6. Verify that the nonce for the sending address is appropriately incremented:

_Note: the nonce value might be different depending on the nonce of the sending EOA_
```
Nonce       0 -> 1
```

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the
`GnosisSafeL2.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up
in your Ledger.

Here is an example screenshot. Note that the hash value may be
different:

<img width="1195" alt="image" src="https://github.com/base-org/contract-deployments/assets/7411939/7d16806c-0408-4d5f-9212-bed4e6fc14f8">

It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones
displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
make sign-op # or make sign-cb for Coinbase signers
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

## [For Facilitator ONLY] How to execute the rehearsal

### [After the rehearsal] Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `make approve-cb` with Coinbase signer signatures.
4. Run `make approve-op` with Optimism signer signatures.
4. Run `make run` to execute the transaction onchain.

