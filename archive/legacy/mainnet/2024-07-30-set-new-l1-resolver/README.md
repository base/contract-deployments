# Update the `Resolver` of the `base.eth` name to the Basenames [L1Resolver](https://github.com/base-org/basenames/blob/v1.0.0/src/L1/L1Resolver.sol)

Status: EXECUTED
https://etherscan.io/tx/0x15a5263c5531d27f6f91cfe79167ddaf0db38a29ce50106ff0e3380b468722df

## Objective

The L1 Resolver contract set via `2024-07-23-set-l1-resolver` runbook had a bug wherein generic `resolve` requests for the `base.eth` name itself were failing. This was due to the fact that the `rootResolver` does not implement the `resolve` method.

The issue with the contract was fixed in [this PR](https://github.com/base-org/basenames/pull/84) and deployed in [this SCM deploy](https://provisioning-reports.cbhq.net/smart-contracts/usernames/29?stage=apply&group=tf_apply). This runbook will set the resolver for the `base.eth` name to the newly deployed, fixed version of the L1 Resolver contract.

## Approving the Update transaction

### 1. Update repo and move to the appropriate folder:
```
cd contract-deployments
git pull
cd mainnet/2024-07-30-set-new-l1-resolver
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".


### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
make sign-set-l1-resolver
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

Navigate to the `State` tab and check that the following state changes are reflected in the simulation; 

The `resolver` address change in the ENS Registry. We expect that the resolver is being set
_from_: [0x480f8f2ffe823dc70f499cc2542c42a3a6ad3f20](https://etherscan.io/address/0x480f8f2ffe823dc70f499cc2542c42a3a6ad3f20)
_to_: [0xde9049636f4a1dfe0a64d1bfe3155c0a14c54f31](https://etherscan.io/address/0xde9049636f4a1dfe0a64d1bfe3155c0a14c54f31)

**ENSRegistryWithFallback** _0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e_
`mapping (bytes32 => tuple) records` 
`bytes32 node`: 0xff1e3c0eb00ec714e34b6114125fbde1dea2f24a72fbf672e7b7fd5690328e10
_where_  `0xff1e...8e10` == `nodehash(base.eth)` 

**Key:** 0x0c2c38386d21b4257e636b2579f626b23f930fbee0cc73a52081e975ea266cff
**Before:** 0x000000000000000000000000480f8f2ffe823dc70f499cc2542c42a3a6ad3f20
**After:** 0x000000000000000000000000de9049636f4a1dfe0a64d1bfe3155c0a14c54f31

**GnosisSafeProxy** _0x14536667Cd30e52C0b458BaACcB9faDA7046E056_
Increments the nonce from 26 -> 27
**Key**: 0x0000000000000000000000000000000000000000000000000000000000000005
**Before**: 0x000000000000000000000000000000000000000000000000000000000000001a
**After**: 0x000000000000000000000000000000000000000000000000000000000000001b 

#### 3.3. Extract the domain hash and the message hash to approve.

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

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
make sign-set-l1-resolver
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


## Execute the output (For Facilitator)

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `make execute`