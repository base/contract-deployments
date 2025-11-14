# Facilitator Instructions: MCM Bridge Config Update & Program Upgrade

## Overview

As a Facilitator, you are responsible for:
1. Creating the bridge config update proposal
2. Preparing the bridge program upgrade buffer
3. Creating the upgrade proposal
4. Merging both proposals into a single MCM proposal
5. Committing and pushing the merged proposal to the repo
6. Coordinating with Signers
7. Collecting signatures
8. Executing the merged proposal on-chain

## Prerequisites

```bash
cd contract-deployments
git pull
cd solana/devnet-alpha/2025-11-14-update-bridge-config
make setup-deps
```

Ensure you have:
- Rust toolchain installed
- Solana CLI installed and configured
- Anchor CLI installed
- Bun installed
- `mcmctl` installed (via `make deps`)
- `eip712sign` installed (via `make deps`)
- A funded Solana wallet configured

## Phase 1: Create Bridge Config Update Proposal

### 1.1. Update .env for config update proposal

Set the following in `.env`:

```bash
# RPC configuration
SOL_RPC_URL=<rpc-url>

# MCM configuration
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json

# Bridge config parameters
BRIDGE_PROGRAM_ID=<bridge-program-id>
BRIDGE_PARTNER_ORACLE_REQUIRED_THRESHOLD=<threshold-value>
```

### 1.2. Generate config update proposal

```bash
make step1-create-set-partner-oracle-config-proposal
```

This creates `set-partner-oracle-config-proposal.json` with the SetPartnerOracleConfig instruction.

### 1.3. Review config proposal

Open and review `set-partner-oracle-config-proposal.json` to verify:
- Bridge program ID is correct
- Partner oracle required threshold matches intended value
- Valid until timestamp is appropriate

## Phase 2: Prepare Bridge Program Upgrade

### 2.1. Clone bridge repo and apply ID patch

Add the following variables to `.env`:

```bash
BRIDGE_REPO=<bridge-repo-url>
BRIDGE_COMMIT=<commit-hash>
ID_PATCH=<path-to-id-patch-file>
```

Then run:

```bash
make step2-clone-bridge
```

This will:
- Remove any existing `bridge` directory
- Clone the bridge repository
- Checkout the specified commit
- Apply the ID patch

### 2.2. Build the bridge program

```bash
make step3-build-program
```

This builds the bridge program using `cargo-build-sbf`. The compiled binary will be in `bridge/solana/target/deploy/bridge.so`.

### 2.3. Write program buffer

Add the following variable to `.env`:

```bash
PROGRAM_BINARY=bridge/solana/target/deploy/bridge.so
```

Then run:

```bash
make step4-write-buffer
```

This will output a buffer address. Copy it and add to `.env`:

```bash
BUFFER=<buffer-address-from-output>
```

### 2.4. Transfer buffer authority to MCM

Add the following variables to `.env`:

```bash
NEW_BUFFER_AUTHORITY=<mcm-authority-pda>
```

Then run:

```bash
make step5-transfer-buffer
```

This transfers the buffer authority from your wallet to the MCM authority PDA. The buffer is now controlled by MCM.

Copy the transaction signature from the output.

### 2.5. Generate set-buffer-authority artifacts

Find the transaction signature from step 2.4 on Solana Explorer and add to `.env`:

```bash
SET_BUFFER_AUTHORITY_SIGNATURE=<transaction-signature>
```

Then generate the artifacts:

```bash
make step6-generate-set-buffer-authority-artifacts
```

This creates `artifacts/set-buffer-authority-artifacts.json` which will be used in the upgrade proposal.

### 2.6. Create upgrade proposal

Add the following variables to `.env`:

```bash
PROGRAM=<bridge-program-address>
SPILL=<your-wallet-address>
```

Note: `BUFFER` was already set in step 2.3.

Then run:

```bash
make step7-create-upgrade-proposal
```

This creates `upgrade-proposal.json` with the program upgrade instruction.

### 2.7. Review upgrade proposal

Open and review `upgrade-proposal.json` to verify:
- Program address matches `PROGRAM`
- Buffer address matches `BUFFER`
- Spill address is correct
- All instructions are correct

## Phase 3: Merge Proposals

### 3.1. Merge config and upgrade proposals

```bash
make step8-merge-proposals
```

This command will:
- Merge `set-partner-oracle-config-proposal.json` and `upgrade-proposal.json`
- Combine all instructions from both proposals
- Calculate the correct `postOpCount` (preOpCount + 2)
- Output the merged proposal to `MCM_PROPOSAL_OUTPUT` (typically `proposal.json`)
- Clean up the temporary proposal files
- Display proposal statistics:
  - Total instruction count
  - preOpCount value
  - postOpCount value

### 3.2. Review merged proposal

Open and review the merged proposal file (specified by `MCM_PROPOSAL_OUTPUT`) to verify:
- Contains both the SetPartnerOracleConfig instruction and the upgrade instruction
- All addresses and parameters are correct
- `postOpCount` equals `preOpCount + 2`

### 3.3. Commit and push

```bash
git add .
git commit -m "Add merged bridge config update and upgrade proposal"
git push
```

## Phase 4: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make sign` and provide their signature.

**Note:** The `sign` command uses `MCM_PROPOSAL_OUTPUT` and `MCM_PROGRAM_ID` which were already set in Phase 1.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, add to `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 5: Execute Merged Proposal

### 5.1. Add execution variables to .env

Add the following variables to `.env`:

```bash
SOL_WS_URL=<websocket-url>
AUTHORITY=<your-wallet-keypair-path>
```

Note: `SOL_RPC_URL`, `MCM_PROGRAM_ID`, `MCM_SIGNATURES_COUNT`, and `MCM_SIGNATURES` were already set in previous phases.

### 5.2. Execute the proposal

```bash
make step10-execute-proposal
```

This command executes all the necessary steps:
- Initialize signatures account
- Append signatures
- Finalize signatures
- Set root
- Execute both operations (config update + program upgrade)

## Phase 6: Verification

### 6.1. Verify config update on Solana Explorer

Visit the Solana Explorer for your network:
- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet
- Devnet-alpha: https://explorer.solana.com/?cluster=custom&customUrl=<devnet-alpha-rpc>

Search for the execution transaction and verify:
- The transaction was successful
- The program logs show `Instruction: SetPartnerOracleConfig`
- The partner oracle required threshold was updated correctly

### 6.2. Verify program upgrade on Solana Explorer

Search for the bridge program address (`$PROGRAM`) and verify:
- The "Last Deployed Slot" is recent
- The upgrade authority is still the MCM authority
- The program was upgraded successfully

### 6.3. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, devnet-alpha, mainnet-beta, etc.).

## Summary of Environment Variables

Here's a complete list of all environment variables needed, organized by phase:

### Phase 1 - Config Update Proposal
```bash
SOL_RPC_URL=<rpc-url>
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false
MCM_PROPOSAL_OUTPUT=proposal.json
BRIDGE_PROGRAM_ID=<bridge-program-id>
BRIDGE_PARTNER_ORACLE_REQUIRED_THRESHOLD=<threshold-value>
```

### Phase 2 - Bridge Upgrade
```bash
BRIDGE_REPO=<bridge-repo-url>
BRIDGE_COMMIT=<commit-hash>
ID_PATCH=<path-to-id-patch-file>
PROGRAM_BINARY=bridge/solana/target/deploy/bridge.so
BUFFER=<buffer-address-from-step-2.3>
NEW_BUFFER_AUTHORITY=<mcm-authority-pda>
SET_BUFFER_AUTHORITY_SIGNATURE=<signature-from-step-2.4>
PROGRAM=<bridge-program-address>
SPILL=<your-wallet-address>
```

### Phase 5 - Execution
```bash
SOL_WS_URL=<websocket-url>
AUTHORITY=<your-wallet-keypair-path>
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Troubleshooting

### If buffer write fails
- Ensure you have enough SOL in your wallet for buffer rent
- Check that the program binary path is correct
- Verify Solana CLI is properly configured with `solana config get`

### If buffer authority transfer fails
- Ensure the buffer address is correct
- Verify the MCM authority PDA is correct
- Check that you own the buffer with `solana program show <buffer-address>`

### If proposal merge fails
- Ensure both proposal files exist
- Verify `jq` is installed on your system (`which jq`)
- Check that both proposals have valid JSON structure

### If execution fails
- Verify all signatures are valid and correctly formatted
- Ensure you have enough signatures to meet the threshold
- Check that the valid until timestamp hasn't expired
- Verify all PDAs and addresses are correct
- Ensure the AUTHORITY wallet has enough SOL for transaction fees
