# MCM Bridge Config Update

Status: READY TO SIGN

## Description

This task updates the bridge config using its MCM authority.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/devnet-alpha/2025-12-22-update-bridge-config
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Verify the Proposal

Before signing, verify the proposal contents to ensure it matches expectations.

#### 3.1. Verify Instruction 1 (Bridge SetPartnerOracleConfig)

**Program ID:**

Open `proposal.json` and verify instruction 1 has program ID: `6YpL1h2a9u6LuNVi55vAes36xNszt2UDm3Zk1kj4WSBm`

**Instruction Data:**

Verify the instruction discriminant matches [SetPartnerOracleConfig](https://github.com/base/bridge/blob/main/solana/programs/bridge/src/lib.rs#L569):

```bash
echo -n "global:set_partner_oracle_config" | shasum -a 256 | cut -c1-16
```

Expected output: `2230e7872a71d99d`

Verify the full instruction data:

```bash
jq -r '.instructions[0].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output: `2230e7872a71d99d00`

This is the discriminant (`2230e7872a71d99d`) followed by the Borsh-encoded threshold value (`00` = 0 in u8).

#### 3.3. Verify Proposal Metadata

Check the proposal metadata in `proposal.json`:

- **validUntil**: `1797990664` (Unix timestamp - verify this is in the future)
- **multisig**: `7BrnaHaHtFDshmyrZFi28r9vzxTqcmTjSZcf7KdLHRhL`
- **preOpCount**: `12`
- **postOpCount**: `13` (should be preOpCount + 1 operation)

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
