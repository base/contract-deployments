# Upgrade OptimismMintableERC20Factory implementation

Status: DONE

## Objective

This task upgrades the `OptimismMintableERC20Factory` implementation, at address [0x4200000000000000000000000000000000000012](https://basescan.org/address/0x4200000000000000000000000000000000000012#code), to point to the newly deployed factory at address [0x6922ac4DbDfEdEa3a1E5535f12c3171f2b964C91](https://basescan.org/address/0x6922ac4dbdfedea3a1e5535f12c3171f2b964c91#code), effectively replacing the old implementation at address [0xc0D3c0d3C0d3c0d3c0D3c0d3c0D3c0D3c0D30012](https://basescan.org/address/0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30012#code).

## Approving the transaction

### 1. Update repo and move to the appropriate folder:

```
cd contract-deployments
git pull
cd mainnet/2024-04-17-upgrade-erc20-factory
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

1. "Network": Check the network is Base Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger.
4. "Success" with a green check mark 


#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Verify that the nonce is incremented for the Nested Multisig under the "GnosisSafeProxy" at address `0x2304cb33d95999dc29f4cef1e35065e670a70050`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000003
After: 0x0000000000000000000000000000000000000000000000000000000000000004
```

2. And for the same contract, verify that this specific execution is approved:

```
Key (if you are an OP signer): 0x9052fb3c2fd9cb5dd17446c311f63a63659a6f571458940b7f0aced851e51d55
Key (if you are a CB signer): 0x967af9182a28f979962ecb388b54737ad2cbe53fbe8f354b8b1a0005bc9abcff
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x0000000000000000000000000000000000000000000000000000000000000001
```

3. Verify that the nonce is incremented for your multisig:

If you are an OP signer - the OP Foundation Multisig should be under the "GnosisSafeProxy" at address `0x28edb11394eb271212ed66c08f2b7893c04c5d65`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000003
After: 0x0000000000000000000000000000000000000000000000000000000000000004
```

If you are a CB signer - the Coinbase Multisig should be under the address `0xd94e416cf2c7167608b2515b7e4102b41efff94f`:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000005
Before: 0x0000000000000000000000000000000000000000000000000000000000000006
After: 0x0000000000000000000000000000000000000000000000000000000000000007
```

4. Verify that the new ERC20 factory implementation has been registered in the ERC20 factory "Proxy" at address `0x4200000000000000000000000000000000000012`:

```
Key: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
Before: 0x000000000000000000000000c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30012
After: 0x0000000000000000000000006922ac4dbdfedea3a1e5535f12c3171f2b964c91
```

5. For the same contract, verify its `initialized` slot has been set to 1:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000000
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x0000000000000000000000000000000000000000000000000000000000000001
```

6. For the same contract, verify the `bridge` address has been correctly registered:

```
Key: 0x0000000000000000000000000000000000000000000000000000000000000001
Before: 0x0000000000000000000000000000000000000000000000000000000000000000
After: 0x0000000000000000000000004200000000000000000000000000000000000010
```

7. Verify that the L1FeeVault at `0x420000000000000000000000000000000000001a` receives the gas associated with the call:

```
Balance 1132449259793366198 -> 1132449525791013671
```

8. Verify that the nonce for the sending address is appropriately incremented:

```
Nonce 0 -> 1
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

![Screenshot 2024-04-18 at 18 53 26](https://github.com/base-org/contract-deployments/assets/33523487/85566275-feab-489d-87e9-6ebc4de7b823)

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

