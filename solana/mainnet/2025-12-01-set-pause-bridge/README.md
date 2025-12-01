# MCM Bridge Pause/Unpause

Status: PENDING

## Description

This task pauses or unpauses the Bridge program using the MCM program. This is a critical security operation that can be used to halt bridge operations in emergency situations or resume them after issues are resolved.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/mainnet/2025-12-01-set-pause-bridge
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Verify the Proposal

Before signing, verify the proposal contents to ensure it matches expectations.

**Verify proposal-level fields:**

- `proposal.json` root field `multisigId` must match `MCM_MULTISIG_ID` from `.env`
- `proposal.json` root field `validUntil` must match `MCM_VALID_UNTIL` from `.env`
- The instruction `programId` must match `BRIDGE_PROGRAM_ID` from `.env`

#### 3.1. Instruction 0: Bridge SetPauseStatus

**Verify discriminant:**

```bash
echo -n "global:set_pause_status" | shasum -a 256 | cut -c1-16
```

Expected output: `761991d972d1ec91`

**Verify full instruction data:**

```bash
jq -r '.instructions[0].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output format: `761991d972d1ec91[PAUSED (1 byte)]`

**Parameters:**

- **paused** (bool, 1 byte): Whether to pause the bridge
  - **Verify:** Must match `PAUSED` from `.env`: `true` = `01` (pause), `false` or omitted = `00` (unpause)

#### 3.2. Verify Proposal Metadata

Check the proposal metadata in `proposal.json`:

- **validUntil**: Should match `MCM_VALID_UNTIL` from `.env` (Unix timestamp, typically within 7 days from now)
- **multisig**: Should match `MCM_MULTISIG_ID` from `.env` (the MCM multisig address for this network)
- **preOpCount**: The operation count before this proposal
- **postOpCount**: Should be preOpCount + 1 (one instruction)

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
