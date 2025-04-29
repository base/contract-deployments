# Upgrade Fault Proofs

Status: READY TO SIGN

## Description

This task contains two scripts. One for deploying new versions of the `FaultDisputeGame` and `PermissionedDisputeGame` contracts, and one for updating the `DisputeGameFactory` contract to reference the new dispute game contracts.

## Initial Setup

These instructions are for initial setup of your development environment to install basic tools (e.g Go, Git etc.) needed for the rest of the README. If you already
have these tools or have used this repo before, feel free to skip this section.

### 1. Install Xcode
 - Download Xcode from the Mac App Store

### 2. Install Xcode Command Line Tools
 - Open the Terminal Application
     - The Terminal Application can be found using LaunchPad and typing in "Terminal"
 - Run the command:
 ```bash
 xcode-select --install
 ```

### 3. Install Golang
 - Naviate to [https://go.dev/doc/install](https://go.dev/doc/install)
 - Click the download button to install the latest version of Golang
 - Follow the installation prompts

### 4. Install Forge
 - Inside Terminal run:
 ```bash
 curl -L https://foundry.paradigm.xyz | bash
 ```

### 5. Clone Repo
 - Inside Terminal run:
 ```bash
 git clone git@github.com:base/contract-deployments.git
 ```

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-04-23-upgrade-fault-proofs
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Run relevant script(s)

#### 3.1 [ONLY for a Base Engineer to run] Deploy new Dispute Game Implementations

```bash
make deploy
```

This will output the new addresses of the `FaultDisputeGame` and `PermissionedDisputeGame` contracts to an `addresses.json` file. You will need to commit this file to the repo before signers can sign.

#### 3.2 Sign the transaction

Coinbase signer:

```bash
make sign-cb
```

Op signer:

```bash
make sign-op
```

Security Council signer:

```bash
make sign-sc
```

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and extract the domain hash and message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

##### 3.2.1 Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not see the derivation path Note above.

##### 3.2.2. Validate correctness of the state diff.

Now click on the "State" tab.

- If **CB Signer**
refer to the [CB State Validations](./validations/CB.md) instructions for the transaction you are signing.

- If **OP Signer**
refer to the [OP State Validations](./validations/OP.md) instructions for the transaction you are signing.

- If **Security Council Signer**
refer to the [Security Council State Validations](./validations/SC.md) instructions for the transaction you are signing.

Once complete return to this document to complete the signing.

##### 3.2.3. Extract the domain hash and the message hash to approve.

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
> domain hash and message hash in the following two places match:
>
> 1. On your Ledger screen.
> 2. In the Tenderly simulation. You should use the same Tenderly
>    simulation as the one you used to verify the state diffs, instead
>    of opening the new one printed in the console.
>
> There is no need to verify anything printed in the console. There is
> no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```shell
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

##### 3.2.4 Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

### [For Facilitator ONLY] How to execute

#### Execute the transaction approvals

1. IMPORTANT: Ensure op-challenger has been updated before executing.
1. Collect outputs from all participating signers.
1. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`.
1. Run the `make approve` command as described below to execute the transaction.

For example, if the quorum is 2 and you get the following outputs:

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

Coinbase facilitator:

```bash
SIGNATURES=AAAABBBB make approve-cb
```

Optimism facilitator:

```bash
SIGNATURES=AAAABBBB make approve-op
```

Security Council facilitator:

```bash
SIGNATURES=AAAABBBB make approve-sc
```

Once `approve-cb` and `approve-sc` have been executed, run:
```bash
make approve-coordinator
```

#### Execute the transaction

Once the signatures have been submitted approving the transaction for all nested Safes run:

```bash
make execute
```
