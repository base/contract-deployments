# Solana Program Upgrade

Status: PENDING

## Description

This task upgrades a Solana program using the BPF Loader v3 upgradeable loader through the MCM (Multi-Chain Multisig) system. The upgrade process involves deploying a new program buffer, transferring authority to the MCM multisig, creating a proposal with the upgrade instruction, collecting signatures from signers, and executing the upgrade on-chain.

## Prerequisites

- Solana CLI installed and configured
- `mcmctl` CLI tool installed (`go install github.com/base/mcm-go/cmd/mcmctl@latest`)
- Access to the Solana cluster (devnet/testnet/mainnet)
- Path to the compiled program binary (`.so` file)
- MCM program ID and multisig ID

## Procedure

### 1. Deploy Buffer (For Facilitator ONLY)

Deploy the new program binary to a buffer account on Solana:

```bash
solana program write-buffer <path_to_program.so> --url <cluster>
```

This will output a buffer address. **Save this address** - you will need it for subsequent steps.

Example output:
```
Buffer: 5TbW9CEvuid2i4LaSxEPVVSfdbqKDgfwRkQjVncaEAmw
```

### 2. Transfer Buffer Authority (For Facilitator ONLY)

Transfer the buffer authority to the MCM multisig authority:

#### 2.1 Calculate MCM Authority

First, calculate the MCM authority address:

```bash
mcmctl multisig print-authority --program-id <mcm_program_id> --multisig-id <multisig_id>
```

**Save this authority address** - you will need it for the next step.

#### 2.2 Set Buffer Authority

Transfer the buffer authority to the MCM authority:

```bash
solana program set-buffer-authority <buffer_address> \
  --new-buffer-authority <mcm_authority> \
  --url <cluster>
```

> [!IMPORTANT]
> After this step, the buffer is controlled by the MCM multisig. Any further operations on this buffer require multisig approval.

### 3. Generate Upgrade Instruction (For Facilitator ONLY)

Generate the BPF Loader v3 upgrade instruction as a JSON file:

```bash
go run main.go \
  --program <program_address> \
  --buffer <buffer_address> \
  --spill <spill_address> \
  --rpc-url <rpc_url> \
  --output upgrade_instruction.json
```

**Parameters:**
- `--program`: The address of the program to upgrade
- `--buffer`: The buffer address from Step 2
- `--spill`: Account to receive refunded lamports (typically your wallet or a designated account)
- `--rpc-url`: Solana RPC endpoint URL
- `--output`: Output file path (default: `upgrade_instruction.json`)

This tool will:
- Derive the ProgramData PDA from the program address
- Fetch and validate authorities from on-chain accounts
- Generate the upgrade instruction in MCM-compatible JSON format

**Output:**
The tool will display derived addresses for verification:
```
Upgrade instruction written to upgrade_instruction.json
Program: <program_address>
ProgramData (derived): <program_data_pda>
Buffer: <buffer_address>
Spill: <spill_address>
Authority: <authority_address>
```

> [!NOTE]
> This instruction JSON file is temporary and only used as input for Step 5. It does not need to be committed to the repository.

### 4. Create MCM Proposal (For Facilitator ONLY)

Create a proposal in the MCM system using the upgrade instruction:

```bash
mcmctl proposal create \
  --instructions upgrade_instruction.json \
  --multisig-id <multisig_id> \
  --valid-until <timestamp> \
  --output proposal.json
```

**Parameters:**
- `--instructions`: Path to the instruction JSON from Step 4
- `--multisig-id`: The 32-byte hex-encoded multisig ID
- `--valid-until`: Unix timestamp until which the proposal is valid
- `--override-previous-root`: (Optional) Override previous root if needed
- `--output`: Output file path for the proposal

This will generate a `proposal.json` file containing:
- The upgrade instruction
- Merkle root
- Metadata required for signing

**Commit this file to the repository** so signers can access it.

### 5. Sign the Proposal (For Signers)

Each signer must independently verify and sign the proposal. Refer to [SIGNERS.md](./SIGNERS.md) for complete instructions.

### 6. Upload Signatures (For Facilitator ONLY)

The Facilitator collects signatures from all signers and uploads them to the MCM system.

#### 6.1 Initialize Signatures

```bash
mcmctl signatures initialize \
  --proposal proposal.json \
  --multisig-id <multisig_id>
```

#### 6.2 Append Signatures

```bash
mcmctl signatures append \
  --proposal proposal.json \
  --multisig-id <multisig_id> \
  --signatures <signer1_addr>:<signature1>,<signer2_addr>:<signature2>,...
```

Repeat this command if uploading signatures in batches.

#### 6.3 Finalize Signatures

```bash
mcmctl signatures finalize \
  --proposal proposal.json \
  --multisig-id <multisig_id>
```

This marks the signature collection as complete and verifies the threshold is met.

### 7. Set Root (For Facilitator ONLY)

Set the proposal root on-chain:

```bash
mcmctl proposal set-root --proposal proposal.json
```

This commits the Merkle root to the MCM contract, allowing operations to be executed.

### 8. Execute Upgrade (For Facilitator ONLY)

Execute the upgrade instruction on-chain:

```bash
mcmctl proposal execute --proposal proposal.json
```

This will:
- Verify the Merkle proof
- Execute the BPF Loader v3 upgrade instruction
- Upgrade the program with the new buffer data
- Transfer refunded lamports to the spill account

> [!NOTE]
> After successful execution, the program will be running the new version deployed in the buffer from Step 2.

### 9. Verify Upgrade

Verify the upgrade was successful:

```bash
solana program show <program_address> --url <cluster>
```

Check that:
1. The program is still upgradeable (has an upgrade authority)
2. The upgrade authority is still the MCM authority
3. The program slot has updated to a recent slot

