# Facilitator Instructions: Bridge Program Upgrade with Rollback

## Overview

As a Facilitator, you are responsible for:
1. Preparing the bridge program upgrade buffer (with patch applied)
2. Preparing the rollback buffer (current program bytecode)
3. Creating a merged upgrade/rollback proposal
4. Coordinating with Signers and collecting signatures
5. Executing the upgrade on-chain
6. Executing the rollback if needed

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
UPGRADE_PATCH=patches/upgrade.patch
```

Then run:

```bash
make step1-clone-bridge
```

This will:
- Remove any existing `bridge` directory
- Clone the bridge repository
- Checkout the specified commit
- Apply the patch from `patches/upgrade.patch`
- Install and build TypeScript clients

### 1.2. Build the bridge programs

```bash
make step2-build-programs
```

This builds the bridge programs. The compiled binary will be in `bridge/solana/target/deploy/bridge.so`.

### 1.3. Write program buffer

Ensure the following variable is set in `.env`:

```bash
PROGRAM_BINARY=./bridge/solana/target/deploy/bridge.so
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

Ensure the following variable is set in `.env`:

```bash
NEW_BUFFER_AUTHORITY=$(MCM_AUTHORITY)
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

This creates `artifacts/set-buffer-authority-artifacts.json`.

## Phase 2: Prepare Rollback Buffer

### 2.1. Dump current program

Ensure the following variable is set in `.env`:

```bash
PROGRAM=<bridge-program-address>
ROLLBACK_PROGRAM_BINARY=./rollback.so
```

Then run:

```bash
make step6-dump-current-program
```

This dumps the current on-chain program bytecode to `rollback.so`.

### 2.2. Write rollback buffer

```bash
make step7-write-rollback-buffer
```

This will output a buffer address. Copy it and add to `.env`:

```bash
ROLLBACK_BUFFER=<rollback-buffer-address-from-output>
```

### 2.3. Transfer rollback buffer authority to MCM

```bash
make step8-transfer-rollback-buffer
```

Copy the transaction signature from the output.

### 2.4. Generate rollback buffer artifacts

Add the transaction signature to `.env`:

```bash
SET_ROLLBACK_BUFFER_AUTHORITY_SIGNATURE=<transaction-signature>
```

Then generate the artifacts:

```bash
make step9-generate-rollback-buffer-artifacts
```

This creates `artifacts/set-rollback-buffer-authority-artifacts.json`.

## Phase 3: Create Merged Proposal

### 3.1. Ensure all MCM variables are set

Verify the following variables are set in `.env`:

```bash
# Common MCM Proposal Variables
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json

# Program upgrade variables
PROGRAM=<bridge-program-address>
BUFFER=<upgrade-buffer-address>
ROLLBACK_BUFFER=<rollback-buffer-address>
SPILL=<your-wallet-address>
```

### 3.2. Create merged proposal

```bash
make step10-create-proposal
```

This creates `proposal.json` containing two instructions:
- Instruction 0: Upgrade to the patched version
- Instruction 1: Rollback to the original version

### 3.3. Review proposal

Open and review `proposal.json` to verify:
- Instructions count is 2
- First instruction uses `BUFFER` (upgrade)
- Second instruction uses `ROLLBACK_BUFFER` (rollback)
- Program address matches `PROGRAM`
- Spill address is correct

## Phase 4: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, add to `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 5: Register and Execute Proposal

### 5.1. Add execution variables to .env

Add the following variables to `.env`:

```bash
AUTHORITY=<your-wallet-keypair-path>
```

### 5.2. Register the proposal

```bash
make step12-register-proposal
```

This command:
- Initializes signatures account
- Appends signatures
- Finalizes signatures
- Sets root

### 5.3. Execute the upgrade

```bash
make step13-execute-upgrade
```

This executes instruction 0 (upgrade to patched version).

### 5.4. Execute the rollback (if needed)

If you need to rollback to the original version:

```bash
make step14-execute-rollback
```

This executes instruction 1 (rollback to original version).

## Phase 6: Verification

### 6.1. Verify program upgrade on Solana Explorer

Visit the Solana Explorer for your network:
- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet

Search for the bridge program address (`$PROGRAM`) and verify:
- The "Last Deployed Slot" is recent
- The upgrade authority is still the MCM authority
- The program was upgraded successfully

### 6.2. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, devnet-alpha, mainnet-beta, etc.).
