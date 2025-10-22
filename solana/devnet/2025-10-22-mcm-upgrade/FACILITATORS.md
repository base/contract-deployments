# Facilitator Instructions: MCM Program Upgrade

## Overview

As a Facilitator, you are responsible for:
1. Preparing the program buffer
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
- Solana CLI installed and configured
- `mcmctl` installed (via `make deps`)
- `eip712sign` installed (via `make deps`)
- A funded Solana wallet configured
- The compiled program binary (`.so` file) ready

## Phase 1: Prepare the Program Buffer

### 1.1. Obtain the compiled program

Get the compiled program binary (`.so` file) that contains the new version of the program.

### 1.2. Update .env for buffer upload

Set the following in `.env`:

```bash
PROGRAM=<program-address>
PROGRAM_BINARY=<path-to-.so-file>
```

### 1.3. Write buffer

```bash
make write-buffer
```

This will output a buffer address. Copy it.

### 1.4. Update .env and transfer buffer authority

Set the following in `.env`:

```bash
BUFFER=<buffer-address-from-write-buffer>
MCM_AUTHORITY=<mcm-authority-pda>
SPILL=<your-wallet-address>
```

Then transfer buffer authority to MCM:

```bash
make transfer-buffer
```

The buffer is now controlled by the MCM authority.

## Phase 2: Create and Commit MCM Proposal

### 2.1. Update .env for proposal generation

Set the following in `.env`:

```bash
MCM_PROGRAM_ID=<mcm-program-id>
MCM_MULTISIG_ID=<multisig-id>
MCM_VALID_UNTIL=<unix-timestamp>
MCM_OVERRIDE_PREVIOUS_ROOT=false  # or true if needed
MCM_PROPOSAL_OUTPUT=proposal.json
```

### 2.2. Generate proposal

```bash
make mcm-proposal
```

This creates the proposal file (default `proposal.json` or whatever is set in `MCM_PROPOSAL_OUTPUT`).

### 2.3. Review proposal

Open and review the generated proposal file to verify:
- Program address matches `PROGRAM`
- Buffer address matches `BUFFER`
- Spill address is correct
- Valid until timestamp is appropriate
- All instructions are correct

### 2.4. Commit and push

```bash
git add .
git commit -m "Add MCM program upgrade proposal for <program-name>"
git push
```

## Phase 3: Coordinate with Signers and Collect Signatures

Coordinate with Signers to collect their signatures. Each Signer will run `make mcm-sign` and provide their signature.

Concatenate all signatures in the format: `0xSIG1,0xSIG2,0xSIG3`

Once you have all required signatures, update `.env`:

```bash
MCM_SIGNATURES_COUNT=<number-of-signatures>
MCM_SIGNATURES=0xSIG1,0xSIG2,0xSIG3
```

## Phase 4: Execute Proposal

```bash
make mcm-all
```

This command executes all the necessary steps:
- Initialize signatures account
- Append signatures
- Finalize signatures
- Set root
- Execute proposal

## Phase 5: Verification

### 5.1. Verify program on Solana Explorer

Visit the Solana Explorer for your network:
- Mainnet: https://explorer.solana.com/
- Devnet: https://explorer.solana.com/?cluster=devnet

Search for the program address (`$PROGRAM`) and verify:
- The "Last Deployed Slot" is recent
- The upgrade authority is still `MCM_AUTHORITY`
- The execution transaction is visible in history

### 5.2. Update README

Update the Status line in README.md to:

```markdown
Status: [EXECUTED](https://explorer.solana.com/tx/<transaction-signature>?cluster=<network>)
```

Replace `<transaction-signature>` with the execution transaction signature and `<network>` with the appropriate cluster (devnet, mainnet-beta, etc.).
