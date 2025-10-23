# Facilitator Instructions: MCM Bridge Pause/Unpause

## Overview

As a Facilitator, you are responsible for:
1. Preparing the bridge pause configuration
2. Creating the MCM proposal
3. Committing and pushing the proposal to the repo
4. Coordinating with Signers
5. Collecting signatures
6. Executing the proposal on-chain

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

## Phase 1: Prepare and Generate Proposal

### 1.1. Update .env with bridge pause configuration

Set the following in `.env`:

```bash
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json

# Bridge configuration
BRIDGE_PROGRAM_ID=<bridge-program-id>
BRIDGE_ACCOUNT=<bridge-account-address>
GUARDIAN=<mcm-authority>
PAUSED=true  # or false to unpause
```

### 1.2. Generate proposal

```bash
make step1-create-proposal
```

This creates the proposal file (default `proposal.json` or whatever is set in `MCM_PROPOSAL_OUTPUT`).

### 1.3. Review proposal

Open and review the generated proposal file to verify:
- Bridge program ID is correct
- Bridge account address is correct
- Guardian address is correct
- Pause status is correct (pausing or unpausing)
- Valid until timestamp is appropriate

### 1.4. Commit and push

```bash
git add .
git commit -m "Add MCM bridge pause/unpause proposal"
git push
```

## Phase 2: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, update `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 3: Execute Proposal

```bash
make step3-execute-proposal
```

This command executes all the necessary steps:
- Initialize signatures account
- Append signatures
- Finalize signatures
- Set root
- Execute proposal

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

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, mainnet-beta, etc.).
