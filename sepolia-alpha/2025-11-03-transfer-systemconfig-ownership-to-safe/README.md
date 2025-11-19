# Transfer SystemConfig Ownership to Gnosis Safe

Status: NOT YET EXECUTED

## Description

We wish to update the owner of our [SystemConfig](https://sepolia.etherscan.io/address/0x7F67DC4959cb3E532B10A99F41bDD906C46FdFdE) contract on Sepolia for Sepolia-Alpha to be the Gnosis safe owned by the Base chain engineers.

**Important Context:**
- The ProxyAdmin owner was previously transferred to the Safe in task `2025-04-08-transfer-proxy-admin-ownership-to-safe`
- However, that transaction only changed the **ProxyAdmin** owner (which controls proxy upgrades)
- The **SystemConfig** owner (which controls SystemConfig parameters) is a separate ownership role
- This task correctly transfers the SystemConfig ownership to match the ProxyAdmin ownership

The current owner is an EOA (0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430) which is not compatible with the superchain-ops upgrade process.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia-alpha/2025-11-03-transfer-systemconfig-ownership-to-safe
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
