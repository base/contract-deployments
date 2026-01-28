# Facilitator Instructions: MCM Bridge Pause/Unpause

## Overview

As a Facilitator, you are responsible for:

1. Preparing the bridge pause/unpause configuration
2. Creating the MCM proposals (both pause and unpause)
3. Committing and pushing the proposals to the repo
4. Coordinating with Signers
5. Collecting signatures for a range of nonces
6. Executing the specific proposal (pause or unpause) onchain when needed

## Prerequisites

```bash
cd contract-deployments
git pull
cd solana/<network>/<task-directory>
make deps
```

Ensure you have:

- `mcmctl` installed (via `make deps`)
- `eip712sign` installed (via `make deps`)
- A funded Solana wallet configured

## Phase 1: Prepare and Generate Proposals

### 1.1. Update .env

Set the following in `.env`:

```bash
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed

# Bridge configuration
BRIDGE_PROGRAM_ID=<bridge-program-id>
```

### 1.2. Generate proposals

Generate both pause and unpause proposals to have them ready for any situation.

```bash
# Generate Pause Proposal (proposal-pause.json)
make step1-create-proposal-pause

# Generate Unpause Proposal (proposal-unpause.json)
make step1-create-proposal-unpause
```

### 1.3. Review proposals

Open and review the generated proposal files (`proposal-pause.json` and `proposal-unpause.json`) to verify:

- Bridge program ID is correct
- Pause status is correct in the instruction data (ends in `01` for pause, `00` for unpause)
- Valid until timestamp is appropriate

### 1.4. Commit and push

```bash
git add .
git commit -m "Add MCM bridge pause/unpause proposals"
git push
```

## Phase 2: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Signers will generate signatures for a range of 20 nonces to ensure a valid signature is available even if other operations occur on the multisig.

Ask signers to run:

- `make sign-pause` (to generate `signatures-pause.txt`)
- `make sign-unpause` (to generate `signatures-unpause.txt`)

Collect these text files from the signers.

## Phase 3: Execute Proposal

When an emergency action (Pause) or recovery (Unpause) is required:

### 3.1. Determine Current Nonce

Check the current `preOpCount` (nonce) of the multisig. You can check this on the Solana Explorer by looking at the Multisig account data, or by inspecting the error if a dry-run fails.

### 3.2. Aggregate Signatures

Concatenate signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

### 3.3. Update .env

Update `.env` with the collected signatures:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

### 3.4. Execute

Run the execution command for the desired action, providing the current nonce. This will update the proposal file to match the chain state and execute it.

**To Pause:**

```bash
NONCE=<current-nonce> make step3-execute-proposal-pause
```

**To Unpause:**

```bash
NONCE=<current-nonce> make step3-execute-proposal-unpause
```

This command will:

- Update the proposal's `preOpCount` and `postOpCount` to match the provided `NONCE`.
- Initialize signatures account.
- Append signatures.
- Finalize signatures.
- Set root.
- Execute proposal.

## Phase 4: Verification

### 4.1. View transaction on Solana Explorer

Visit the Solana Explorer for your network:

- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet

Search for the execution transaction and verify:

- The transaction was successful
- The program logs show `Instruction: SetPauseStatus` (Anchor log)
- The pause status matches the intended action (paused or unpaused)

### 4.2. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```
