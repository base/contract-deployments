# Facilitator Instructions: MCM Signers Update

## Overview

As a Facilitator, you are responsible for:
1. Preparing the new signers configuration
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

### 1.1. Update .env with signers configuration

Set the following in `.env`:

```bash
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json

# New signers configuration
MCM_NEW_SIGNERS=0xADDRESS1,0xADDRESS2,0xADDRESS3
MCM_SIGNER_GROUPS=0,0,1
MCM_GROUP_QUORUMS=2,1
MCM_GROUP_PARENTS=0,0
MCM_CLEAR_ROOT=false  # or true if needed
```

**Important**: Carefully review the signers configuration to ensure it matches the intended governance structure.

### 1.2. Generate proposal

```bash
make mcm-proposal
```

This creates the proposal file (default `proposal.json` or whatever is set in `MCM_PROPOSAL_OUTPUT`).

### 1.3. Review proposal

Open and review the generated proposal file to verify:
- All new signers are included
- Signer groups are correctly assigned
- Group quorums are appropriate
- Group parent relationships are correct
- Valid until timestamp is appropriate

### 1.4. Commit and push

```bash
git add .
git commit -m "Add MCM signers update proposal"
git push
```

## Phase 2: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make mcm-sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, update `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 3: Execute Proposal

```bash
make mcm-all
```

This command executes all the necessary steps:
- Initialize signatures account
- Append signatures
- Finalize signatures
- Set root
- Execute proposal

## Phase 4: Verification

### 4.1. Verify MCM configuration

```bash
make mcm-print-config
```

Check that:
- All new signers are present
- Old signers (if removed) are no longer present
- Signers are in the correct groups
- Group quorums are set correctly
- Group parent relationships are correct

### 4.2. View on Solana Explorer

Visit the Solana Explorer for your network:
- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet

Search for the execution transaction to verify the update.

### 4.3. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, mainnet-beta, etc.).
