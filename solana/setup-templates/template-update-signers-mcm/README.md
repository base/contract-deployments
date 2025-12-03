# MCM Signers Update via Multi-Chain Multisig

Status: PENDING

## Description

This task updates the signers configuration for a Multi-Chain Multisig (MCM) instance. This includes adding or removing signers, modifying signer groups, adjusting group quorums, and updating group parent relationships.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/<network>/<task-directory>
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Verify the Proposal

Before signing, verify the proposal contents to ensure it matches expectations.

#### 3.1. Verify Program ID

Open `proposal.json` and verify that all instructions use the MCM program ID. The program ID should be documented in the task-specific README or deployment artifacts.

#### 3.2. Verify Instruction Sequence

The MCM signer update process involves multiple instructions in a specific sequence:
- **(Optional) ClearSigners** - only if `MCM_CLEAR_SIGNERS=true` in `.env`
- **0: InitSigners**
- **1..N: AppendSigners** - one or more (batches of max 10 signers each)
- **N+1: FinalizeSigners**
- **N+2: SetConfig**

**Before verifying individual instructions, check:**
- All instructions must use `MCM_PROGRAM_ID` as their `programId`
- `proposal.json` root field `multisigId` must match `MCM_MULTISIG_ID` from `.env`
- `proposal.json` root field `validUntil` must match `MCM_VALID_UNTIL` from `.env`

#### 3.2.1. (Optional) ClearSigners

This instruction is only present if `MCM_CLEAR_SIGNERS=true` in `.env`.

**Verify discriminant:**

```bash
echo -n "global:clear_signers" | shasum -a 256 | cut -c1-16
```

Expected output: `5a8caa92804b64af`

**Verify full instruction data:**

```bash
jq -r '.instructions[N].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `5a8caa92804b64af[MULTISIG_ID (32 bytes)]`

**Parameters:**
- **multisig_id** (32 bytes): The multisig instance identifier
  - **Verify:** Must match `MCM_MULTISIG_ID` from `.env`

#### 3.2.2. Instruction 0: InitSigners

Initializes the signer storage.

**Verify discriminant:**

```bash
echo -n "global:init_signers" | shasum -a 256 | cut -c1-16
```

Expected output: `66b681108a8edfc4`

**Verify full instruction data:**

```bash
jq -r '.instructions[N].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `66b681108a8edfc4[MULTISIG_ID (32 bytes)][TOTAL_SIGNERS (1 byte)]`

**Parameters:**
- **multisig_id** (32 bytes): The multisig instance identifier
  - **Verify:** Must match `MCM_MULTISIG_ID` from `.env`
- **total_signers** (u8, 1 byte): Total number of signers to be added
  - **Verify:** Must equal the count of comma-separated addresses in `MCM_NEW_SIGNERS` from `.env`

#### 3.2.3. Instructions 1..N: AppendSigners

Adds signer addresses in batches. May appear multiple times (max 10 signers per batch).

**Verify discriminant:**

```bash
echo -n "global:append_signers" | shasum -a 256 | cut -c1-16
```

Expected output: `eed1fb2729f19219`

**Verify full instruction data:**

```bash
jq -r '.instructions[N].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `eed1fb2729f19219[MULTISIG_ID (32 bytes)][VEC_LENGTH (u32 LE, 4 bytes)][SIGNER_1 (20 bytes)]...[SIGNER_N (20 bytes)]`

**Parameters:**
- **multisig_id** (32 bytes): The multisig instance identifier
  - **Verify:** Must match `MCM_MULTISIG_ID` from `.env`
- **signers_batch** (Vec<[u8; 20]>):
  - Length (u32 little-endian, 4 bytes): Number of signers in this batch
  - Signer addresses (20 bytes each): Ethereum addresses
  - **Verify:** All signer addresses across all AppendSigners instructions (concatenated in order) must match the comma-separated addresses in `MCM_NEW_SIGNERS` from `.env`

**Note:** Total signers across all AppendSigners instructions must match `total_signers` from InitSigners.

#### 3.2.4. Instruction N+1: FinalizeSigners

Finalizes the signer list.

**Verify discriminant:**

```bash
echo -n "global:finalize_signers" | shasum -a 256 | cut -c1-16
```

Expected output: `31fe9ae289c7783f`

**Verify full instruction data:**

```bash
jq -r '.instructions[N].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `31fe9ae289c7783f[MULTISIG_ID (32 bytes)]`

**Parameters:**
- **multisig_id** (32 bytes): The multisig instance identifier
  - **Verify:** Must match `MCM_MULTISIG_ID` from `.env`

#### 3.2.5. Instruction N+2: SetConfig

Sets the final multisig configuration (groups, quorums, and parents).

**Verify discriminant:**

```bash
echo -n "global:set_config" | shasum -a 256 | cut -c1-16
```

Expected output: `6c9e9aafd4623442`

**Verify full instruction data:**

```bash
jq -r '.instructions[N].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `6c9e9aafd4623442[MULTISIG_ID (32 bytes)][SIGNER_GROUPS_VEC_LENGTH (u32 LE, 4 bytes)][SIGNER_GROUPS (N bytes)][GROUP_QUORUMS (32 bytes)][GROUP_PARENTS (32 bytes)][CLEAR_ROOT (1 byte)]`

**Parameters:**
- **multisig_id** (32 bytes): The multisig instance identifier
  - **Verify:** Must match `MCM_MULTISIG_ID` from `.env`
- **signer_groups** (Vec<u8>):
  - Length (u32 little-endian, 4 bytes): Number of signers
  - Group assignments (u8, 1 byte each): Group ID for each signer
  - **Verify:** Must match comma-separated values in `MCM_SIGNER_GROUPS` from `.env`
- **group_quorums** (array of 32 u8): Quorum threshold for each group
  - **Verify:** Must match comma-separated values in `MCM_GROUP_QUORUMS` from `.env` (remaining bytes padded with zeros)
- **group_parents** (array of 32 u8): Parent group ID for each group
  - **Verify:** Must match comma-separated values in `MCM_GROUP_PARENTS` from `.env` (remaining bytes padded with zeros)
- **clear_root** (bool, 1 byte): Whether to clear the previous root
  - **Verify:** Must match `MCM_CLEAR_ROOT` from `.env`: `true` = `01`, `false` or omitted = `00`

#### 3.3. Verify Proposal Metadata

Check the proposal metadata in `proposal.json`:

- **validUntil**: Unix timestamp - verify this is in the future (typically within 7 days)
- **multisig**: The MCM multisig address for this network
- **preOpCount**: The operation count before this proposal
- **postOpCount**: Should be preOpCount + total number of instructions

### 4. Sign the proposal

```bash
make sign
```

This command will:
1. Display the proposal hash
2. Prompt you to sign on your Ledger
3. Output your signature

**Verify on your Ledger**: Check that the data you're signing matches the proposal hash displayed in the terminal.

After signing, you will see output like:

```
Signature: 1234567890abcdef...
```

### 5. Send signature to Facilitator

Copy the **entire signature** and send it to the Facilitator via your secure communication channel.

**That's it!** The Facilitator will collect all signatures and execute the proposal.

## For Facilitators

See [FACILITATORS.md](./FACILITATORS.md) for complete instructions on preparing, executing, and verifying this task.
