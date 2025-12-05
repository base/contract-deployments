# MCM Bridge Pause/Unpause

Status: PENDING

## Description

This task pauses or unpauses the Bridge program using the MCM program. This is a critical security operation that can be used to halt bridge operations in emergency situations or resume them after issues are resolved.

There are two separate workflows available:

1. **Pause**: Halts all bridge operations.
2. **Unpause**: Resumes bridge operations.

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

Identify which action you are signing for (Pause or Unpause) and verify the corresponding proposal file.

#### If Pausing (`proposal-pause.json`)

**Verify proposal-level fields:**

- `proposal-pause.json` root field `multisigId` must match `MCM_MULTISIG_ID` from `.env`
- `proposal-pause.json` root field `validUntil` must match `MCM_VALID_UNTIL` from `.env`
- The instruction `programId` must match `BRIDGE_PROGRAM_ID` from `.env`

**Verify instruction data:**

1. **Discriminant:**

   ```bash
   echo -n "global:set_pause_status" | shasum -a 256 | cut -c1-16
   ```

   Expected output: `761991d972d1ec91`

2. **Full instruction data:**

   ```bash
   jq -r '.instructions[0].data' proposal-pause.json | base64 -d | xxd -p -c 256
   ```

   Expected output: `761991d972d1ec9101` (ends in `01` for `true`)

#### If Unpausing (`proposal-unpause.json`)

**Verify proposal-level fields:**

- `proposal-unpause.json` root field `multisigId` must match `MCM_MULTISIG_ID` from `.env`
- `proposal-unpause.json` root field `validUntil` must match `MCM_VALID_UNTIL` from `.env`
- The instruction `programId` must match `BRIDGE_PROGRAM_ID` from `.env`

**Verify instruction data:**

1. **Discriminant:** (Same as above)

2. **Full instruction data:**
   ```bash
   jq -r '.instructions[0].data' proposal-unpause.json | base64 -d | xxd -p -c 256
   ```
   Expected output: `761991d972d1ec9100` (ends in `00` for `false`)

### 4. Sign the proposal

Run the signing command for the appropriate action. **Note: This process requires signing multiple times (20 times) to generate signatures for future nonces.**

**To Pause:**

```bash
make sign-pause
```

**To Unpause:**

```bash
make sign-unpause
```

This command will:

1. Iterate 20 times, incrementing the nonce (preOpCount/postOpCount).
2. Prompt you to sign on your Ledger for each iteration.
3. Save all signatures to a text file (`signatures-pause.txt` or `signatures-unpause.txt`).

**Verify on your Ledger**: Check that the data you're signing matches the proposal hash displayed in the terminal for each iteration.

### 5. Send signature to Facilitator

Send the generated signature file (`signatures-pause.txt` or `signatures-unpause.txt`) to the Facilitator via your secure communication channel.

**That's it!** The Facilitator will collect all signatures and execute the proposal.

## For Facilitators

See [FACILITATORS.md](./FACILITATORS.md) for complete instructions on preparing, executing, and verifying this task.
