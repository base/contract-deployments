# Upgrade 15 - Fault Proof Upgrades for Isthmus

Status: READY TO SIGN

## Description

This task upgrades the smart contracts as part of [Upgrade 15](https://docs.optimism.io/notices/upgrade-15) (governance approval [here](https://vote.optimism.io/proposals/8705916809146420472067303211131851783087744913535435360574720946039078686841)). Several contract changes needed for Isthmus were already included in Upgrade 14, so this upgrade mostly updates the fault proof contracts to be compatible with other changes in Isthmus.

This task contains two scripts. One for deploying new versions of the `FaultDisputeGame` and `PermissionedDisputeGame` contracts, and one for updating the `DisputeGameFactory` contract to reference the new dispute game contracts.

If this is your first signing task, follow the initial setup instructions below. If you have previously signed tasks in this repo, you can skip directly to the [Procedure](#procedure).

## Initial Setup

These instructions are for initial setup of your development environment to install basic tools (e.g Go, Git etc.) needed for the rest of the README.

### 1. Install Homebrew

Open your terminal and run the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Once the installation completes, follow next steps

You should see "next steps" in your terminal. Copy/paste the suggested commands. They should look like:

```bash
echo >> /Users/yourname/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/yourname/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Install Golang

```bash
brew install go
```

### 4. Install Foundry if Needed

Inside Terminal run:

```bash
forge --version
```

If you see an output that starts with `forge Version`, you have foundry installed and can proceed to the next step.

If you do not get an output from `forge --version`, you need to install foundry with:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

After installation completes, quit / re-open your terminal and run:

```bash
foundryup
```

If you see a `libusb` warning (`warning: libusb not found...`), you can safely ignore it and continue to the next step.

### 5. Make a free [Tenderly](https://tenderly.co/) account if you don't already have one.

We will use this later on for simulating and validating the task transaction.

### 6. Clone Repo

Inside Terminal run:

```bash
git clone https://github.com/base/contract-deployments.git
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

Connect and unlock your Ledger with your 8-digit pin. Open the Ethereum application on Ledger so it displays the message "Application is ready".

### 3. Produce Simulation

Run one of the following commands in your terminal based on which signer you are. Please note that blind signing must first be enabled on your Ledger.

Security Council signer:

```bash
make sign-sc
```

Coinbase signer:

```bash
make sign-cb
```

Optimism signer:

```bash
make sign-op
```

You will see a "Simulation link" from the output (yes, it's a big link). Paste the URL from your terminal in your browser. A prompt may ask you to choose a project, any project will do. You can create one if necessary.

If you see the following text after the link in your terminal, "Insert the following hex into the 'Raw input data' field:", the following 2 steps are required.

1. Click the "Enter raw input data" option towards the bottom of the `Contract` component on the left side of your screen in Tenderly.
2. Paste the data string below "Insert the following hex into the 'Raw input data' field:" in your terminal into the "Raw input data" field.

Click "Simulate Transaction".

Example link below (just for reference):

```txt
https://dashboard.tenderly.co/TENDERLY_USERNAME/TENDERLY_PROJECT/simulator/new?network=1&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38&stateOverrides=%5B%7B"contractAddress":"0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D,%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000003","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D,%7B"key":"0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0","value":"0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11"%7D,%7B"key":"0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D,%7B"contractAddress":"0x9855054731540A48b28990B63DcF4f33d8AE46A1","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D,%7B"contractAddress":"0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D%5D
```

### 4. Validate Simulation

We will be performing 3 validations and extract the domain hash and message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

> [!NOTE]
> Ensure you have "Dev Mode" turned on in Tenderly for these validations. This switch is usually located towards the top right of the Tenderly UI.

#### 4.1. Validate integrity of the simulation.

Make sure you are on the "Summary" tab of the tenderly simulation, to validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not see the derivation path Note above.

#### 4.2. Validate correctness of the state diff.

Now click on the "State" tab.

- If **Security Council Signer** refer to the [Security Council State Validations](./validations/SC.md) instructions for the transaction you are signing.

- If **CB Signer** refer to the [CB State Validations](./validations/CB.md) instructions for the transaction you are signing.

- If **OP Signer** refer to the [OP State Validations](./validations/OP.md) instructions for the transaction you are signing.

Once complete return to this document to complete the signing.

#### 4.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right operation, we need to extract the domain hash and the message hash to approve.

Go back to the "Summary" tab in the Tenderly UI, and find the `Safe.checkSignatures` call. This call's `data` parameter contains both the domain hash and the message hash that will show up in your Ledger.

It will be a concatenation of `0x1901`, the domain hash, and the message hash, in the format: **`0x1901[domain hash][message hash]`**.

Note down this value. You will need to compare it with the ones displayed on the Ledger screen at signing.

### 5. Sign the Transaction

Once the validations are done, it's time to actually sign the transaction.

**Note: if your ledger is displaying the lock screen, you will need to unlock your Ledger again before running the sign command.**

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

After verification, sign the transaction. You will see the `Data`, `Signer` and `Signature` printed in the console. Format should be something like this:

```shell
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is your ledger address.

### 6. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which will be collected by Facilitators for execution. Execution can occur by anyone once a threshold of signatures are collected, so a Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and congrats, you are done!
