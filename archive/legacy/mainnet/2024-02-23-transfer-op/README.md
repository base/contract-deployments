# Transfer and Delegate OP Tokens

Status: WILL NOT EXECUTE - see updated task in 2024-07-30-transfer-op

## Objective

When Base launched, Optimism granted a share of OP tokens to Coinbase. The token distribution occurs onchain, and vests over a period of 6 years, with the first vesting event in July 2024. A smart contract handles the logic to make the tokens available for distribution as they vest. This smart contract (the "Smart Escrow Contract") also receives OP tokens 1 year before they vest and stores them until vesting. However, since the Smart Escrow contract was not ready upon Base launch, the existing OP tokens are being stored in a 2-of-2 multisig with CB & OP signers (similar to the multisig used for Base's upgrade keys, except on the Optimism network). 

Now that the Smart Escrow contract is live, this task moves any existing OP tokens from the 2-of-2 multisig to the Smart Escrow contract.

The one caveat is that some amount of the tokens (the "upfront grant") is available to be used by Coinbase for governance purposes, and since the Smart Escrow contract does not support governance use cases, these tokens will remain in the 2-of-2 and be sent directly to Coinbase upon vesting in July 2024. In the meantime, we will do a 1 time delegation of these tokens to a Coinbase owned address, so they can be used for governance purposes prior to July. This delegation event is also handled in this signing task.

## Approving the transaction

### 1. Update repo and move to the appropriate folder:

```
cd contract-deployments
git pull
cd mainnet/2024-02-23-transfer-op
make deps
make install-agora
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
Key (if you are an OP signer): 0x36052d50e52fd56e1e5ef2bf9000ecb5fdb428f034f8a3e05880448b8f161877
Key (if you are a CB signer): 0xff52d03d7d7be46582113567dad0fd34f0eebc222f5fc655b711ba09f22bdb1f
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x0000000000000000000000000000000000000000000000000000000000000001
```

3. Verify that the nonce is incremented for your multisig.

If you are an OP signer - the OP Foundation Multisig should be under the "GnosisSafeProxy" at address `0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x000000000000000000000000000000000000000000000000000000000000007a
After: 0x000000000000000000000000000000000000000000000000000000000000007b
```

If you are a CB signer - the Coinbase Multisig should be under the address `0x6e1dfd5c1e22a4677663a81d24c6ba03561ef0f6`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000001
After: 0x0000000000000000000000000000000000000000000000000000000000000002
```

4. Verify that the state changes for the OP ERC20 token match the expected balance updates. Specifically, verify that the delegate  for the Nested Multisig is established as: `0x85e870a853a55c312bbfdb16c1f64d36916b6629`. Under the `_delegates` field, look for the following state change:

```
0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940      0x0000000000000000000000000000000000000000 -> 0x85e870a853a55c312bbfdb16c1f64d36916b6629
```

5. Under the "Optimism ERC-20" `_balances` field, look for the following state changes:

```
0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940      37580963000000000000000000 -> 10737418000000000000000000
0x1a984e693f8a9c38f3ae1f1af14b677ac245dead      0 -> 26843545000000000000000000
```

6. Verify that the Agora "Alligator Proxy" subdelegate is established correctly. Under the "ERC1967 Proxy" at `0x7f08f3095530b67cdf8466b7a923607944136df0`, expand the state by clicking on the "+" for `0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940`. Verify that the following state change is expected:

```
mapping (address => mapping (address => tuple)) subdelegations
  0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940
    0x635fb974f09b269bc750bf96338c29cf41430125
      maxRedelegations 0 -> 1
      allowanceType 0 -> 10737418000000000000000000
```

Here, the associated events might help add some context. If necessary for clarity, cross check this state transition with the associated events in the "Events" tab:

Verify that the call emitted `DelegateVotesChanged` with a new balance of `10737418000000000000000000` with details:
```json
{
  "delegate": "0x85e870a853a55c312bbfdb16c1f64d36916b6629",
  "previousBalance": "0",
  "newBalance": "10737418000000000000000000"
}
```

Verify that the call emitted `SubDelegation`, specifying an allowance of `10737418000000000000000000` with details:
```json
{
  "from": "0x0a7361e734cf3f0394b0fc4a45c74e7a4ec70940",
  "to": "0x635fb974f09b269bc750bf96338c29cf41430125",
  "subdelegationRules": {
    "maxRedelegations": 1,
    "blocksBeforeVoteCloses": 0,
    "notValidBefore": 0,
    "notValidAfter": 0,
    "customRule": "0x0000000000000000000000000000000000000000",
    "allowanceType": 0,
    "allowance": "10737418000000000000000000"
  }
}
```

7. Verify that the `L1FeeVault` at `0x420000000000000000000000000000000000001a` receives the gas associated with the call:

_Note: the balance values here will not be exactly the same_
```
Balance     3335732882538676762398 -> 3335734048351707566580
```

8. Verify that the nonce for the sending address is appropriately incremented:

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

