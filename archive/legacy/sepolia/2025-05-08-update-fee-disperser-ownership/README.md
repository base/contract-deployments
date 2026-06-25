# Transfer Fee Disperser Ownership to Base Sepolia Eng Multisig

Status: [EXECUTED](https://sepolia.basescan.org/tx/0x7c724ca80756c64c93967be6eee37f6a0ee74e59ebed5773374a7d0da3eb5a68)

## Description

This task updates the owner of our [FeeDisperser](https://sepolia.basescan.org/address/0x76355A67fCBCDE6F9a69409A8EAd5EaA9D8d875d) contract on Base Sepolia to be the aliased address of our [Base Sepolia Eng Multisig](https://sepolia.etherscan.io/address/0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f).

For more information on deriving L1 aliased addresses in the OP stack, see [here](https://docs.optimism.io/stack/differences#address-aliasing).

## Procedure

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2025-05-08-update-fee-disperser-ownership
make deps
```

### 2. Run relevant script(s)

#### Simulate the transaction

```bash
make sim-transfer
```

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.

##### 2.1 Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Base Sepolia.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not see the derivation path Note above.

##### 2.2. Validate correctness of the state diff.

Now click on the "State" tab, and refer to the [State Validations](./VALIDATION.md) instructions for the transaction you are sending.
Once complete return to this document to complete the execution.

#### Execute the transaction

The `transfer` make command expects a Foundry EOA account set up in the keystore by the name of `sepolia-fee-disperser-owner`. If your account name is different, or you wish to pass in a hex private key instead, you will need to modify the Makefile command accordingly.

Once the account is set up, execute the transfer by running:

```bash
make transfer
```
