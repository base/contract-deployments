# Transfer Proxy Admin Ownership to Gnosis Safe

Status: EXECUTED (https://sepolia.etherscan.io/tx/0x35ea2479c054639acd2547f53c47fe166caf1c6c7b5cfebfff5178532135c122)

## Description

We wish to update the owner of our [ProxyAdmin](https://sepolia.etherscan.io/address/0xC5aE9023bFA79124ffA50169E1423E733D0166f1) contract on Sepolia for Sepolia-Alpha to be a Gnosis safe owned by the Base chain engineers. The current owner is an EOA which is not compatible with the superchain-ops upgrade process, nor is it analogous to our standard task setup for this repo.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia-alpha/2025-04-08-transfer-proxy-admin-ownership-to-safe
make deps
```

### 2. Run relevant script(s)

#### Simulate the transaction

```bash
make simulate
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

1. "Network": Check the network is Sepolia.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not see the derivation path Note above.

##### 2.2. Validate correctness of the state diff.

Now click on the "State" tab, and refer to the [State Validations](./VALIDATION.md) instructions for the transaction you are sending.
Once complete return to this document to complete the execution.

#### Execute the transaction

```bash
make execute
```
