# Facilitator Instructions: Deploy MCM on Devnet

## Overview

As a Facilitator, you are responsible for:
1. Cloning and patching the MCM program source
2. Deploying the MCM program
3. Initializing the multisig and signers
4. Creating and executing the ownership transfer proposal
5. Transferring the program upgrade authority

## Prerequisites

```bash
cd contract-deployments
git pull
cd solana/devnet/2025-10-13-deploy-mcm
make deps
```

Ensure you have:
- Solana CLI installed and configured
- Anchor CLI installed
- `mcmctl` installed (via `make deps`)
- `eip712sign` installed (via `make deps`)
- A funded Solana wallet configured

## Phase 1: Clone and Deploy MCM Program

### 1.1. Clone MCM repository

```bash
make mcm-clone
```

This clones the chainlink-ccip repository, checks out the audited commit, and applies the necessary patch.

### 1.2. Deploy MCM program

```bash
make mcm-deploy
```

This deploys the MCM program to Devnet. Note the deployed program ID from the output.

### 1.3. Update .env with program ID

Update `.env` with the deployed MCM program ID:

```bash
MCM_PROGRAM_ID=<deployed-program-id-from-deploy-output>
```

## Phase 2: Initialize Multisig

### 2.1. Initialize multisig

```bash
make mcm-init
```

This initializes the MCM multisig instance on-chain.

### 2.2. Get MCM authority

Run the following command to get the MCM authority PDA:

```bash
make mcm-print-authority
```

Copy the authority address from the output.

### 2.3. Update .env with authority

Update `.env` with the MCM authority:

```bash
MCM_AUTHORITY=<authority-from-print-authority-output>
```

## Phase 3: Configure Signers

### 3.1. Update .env with signers configuration

Before initializing signers, set the following in `.env`:

```bash
MCM_SIGNER_COUNT=<number-of-signers>
MCM_SIGNERS=0xADDRESS1,0xADDRESS2,...
MCM_SIGNER_GROUPS=0,0,1,...
MCM_GROUP_QUORUMS=2,1,...
MCM_GROUP_PARENTS=0,0,...
```

### 3.2. Initialize signers

```bash
make mcm-init-signers
```

This command:
- Initializes the signers account
- Appends all initial signers
- Finalizes the signers list
- Sets the signer group configuration
- Prints the final configuration

Verify the output shows the correct signer configuration.

## Phase 4: Prepare Ownership Transfer Proposal

### 4.1. Update .env with proposal parameters

Before generating the proposal, set the following in `.env`:

```bash
MCM_PROPOSAL_OUTPUT=accept_ownership_proposal.json
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false
```

### 4.2. Generate ownership transfer proposal

```bash
make mcm-proposal
```

This creates the acceptance proposal file.

### 4.3. Review proposal

Open and review the proposal file to verify it contains the correct acceptance operation.

### 4.4. Commit and push

```bash
git add .
git commit -m "Add MCM deployment and ownership transfer proposal"
git push
```

## Phase 5: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make mcm-sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, update `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 6: Execute Ownership Transfer

### 6.1. Transfer ownership to MCM authority

```bash
make mcm-transfer-ownership
```

This command:
- Proposes the MCM authority as the new owner
- Executes all steps to accept ownership (init signatures, append, finalize, set root, execute)
- Prints the final configuration

## Phase 7: Transfer Upgrade Authority

### 7.1. Transfer program upgrade authority

```bash
make mcm-transfer-upgrade-authority
```

This transfers the MCM program's upgrade authority to the MCM authority PDA and shows the program info.

## Phase 8: Verification

### 8.1. Verify MCM configuration

```bash
make mcm-print-config
```

Check that:
- All expected signers are present
- Signers are in the correct groups
- Group quorums are set correctly
- The multisig owner is `MCM_AUTHORITY`

### 8.2. View on Solana Explorer

Visit https://explorer.solana.com/?cluster=devnet

Search for the MCM program (`MCM_PROGRAM_ID`) and verify:
- "Last Deployed Slot" is recent
- Upgrade authority is `MCM_AUTHORITY`
- All deployment and configuration transactions are successful

### 8.3. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/address/<MCM_PROGRAM_ID>?cluster=devnet)
```

Use the MCM program address as the reference link.
