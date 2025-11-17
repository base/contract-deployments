# Facilitator Instructions: Bridge Program Upgrade

## Overview

As a Facilitator, you are responsible for:
1. Preparing the bridge program upgrade buffer
2. Creating the upgrade proposal
3. Coordinating with Signers and collecting signatures
4. Executing the proposal on-chain

## Prerequisites

```bash
cd contract-deployments
git pull
cd solana/<network>/<task-directory>
make setup-deps
```

Ensure you have:
- Rust toolchain installed (via `make setup-deps`)
- Solana CLI installed and configured (via `make setup-deps`)
- Anchor CLI installed 
- `mcmctl` installed (via `make deps`)
- `eip712sign` installed (via `make deps`)
- A funded Solana wallet configured

## Phase 1: Prepare Bridge Program Upgrade

### 1.1. Update .env for bridge program upgrade

Set the following in `.env`:

```bash
BRIDGE_REPO=<bridge-repo-url>
BRIDGE_COMMIT=<commit-hash>
```

Then run:

```bash
make step1-clone-bridge
```

This will:
- Remove any existing `bridge` directory
- Clone the bridge repository
- Checkout the specified commit

### 1.2. Build the bridge program

```bash
make step2-build-program
```

This builds the bridge program using `cargo-build-sbf`. The compiled binary will be in `bridge/solana/target/deploy/bridge.so`.

### 1.3. Write program buffer

Add the following variable to `.env`:

```bash
PROGRAM_BINARY=bridge/solana/target/deploy/bridge.so
```

Then run:

```bash
make step3-write-buffer
```

This will output a buffer address. Copy it and add to `.env`:

```bash
BUFFER=<buffer-address-from-output>
```

### 1.4. Transfer buffer authority to MCM

Add the following variables to `.env`:

```bash
MCM_AUTHORITY=<mcm-authority-pda>
```

Then run:

```bash
make step4-transfer-buffer
```

This transfers the buffer authority from your wallet to the MCM authority PDA. The buffer is now controlled by MCM.

Copy the transaction signature from the output.

### 1.5. Generate set-buffer-authority artifacts

Find the transaction signature from step 1.4 on Solana Explorer and add to `.env`:

```bash
SET_BUFFER_AUTHORITY_SIGNATURE=<transaction-signature>
```

Then generate the artifacts:

```bash
make step5-generate-set-buffer-authority-artifacts
```

This creates `artifacts/set-buffer-authority-artifacts.json` which will be used in the upgrade proposal.

### 1.6. Create upgrade proposal

Add the following variables to `.env`:

```bash
# Common MCM Proposal Variables
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json

PROGRAM=<bridge-program-address>
SPILL=<your-wallet-address>
```

Then run:

```bash
make step6-create-upgrade-proposal
```

This creates `upgrade-proposal.json` with the program upgrade instruction.

### 1.7. Review upgrade proposal

Open and review `upgrade-proposal.json` to verify:
- Program address matches `PROGRAM`
- Buffer address matches `BUFFER`
- Spill address is correct
- All instructions are correct

## Phase 2: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, add to `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 3: Execute Proposal

### 3.1. Add execution variables to .env

Add the following variables to `.env`:

```bash
AUTHORITY=<your-wallet-keypair-path>
```

### 3.2. Execute the proposal

```bash
make step8-execute-proposal
```

This command executes all the necessary steps:
- Initialize signatures account
- Append signatures
- Finalize signatures
- Set root
- Execute both operations (config update + program upgrade)

## Phase 4: Verification

### 4.1. Verify program upgrade on Solana Explorer

Visit the Solana Explorer for your network:
- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet

Search for the bridge program address (`$PROGRAM`) and verify:
- The "Last Deployed Slot" is recent
- The upgrade authority is still the MCM authority
- The program was upgraded successfully

### 4.2. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, devnet-alpha, mainnet-beta, etc.).