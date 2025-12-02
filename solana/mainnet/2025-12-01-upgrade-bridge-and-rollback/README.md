# Upgrade Bridge Program with Rollback

Status: READY TO SIGN

## Description

This task performs a test upgrade of the bridge program followed by a rollback using the Multi-Chain Multisig (MCM) governance system.

The proposal contains two instructions:
- **Instruction 0**: Upgrade to the patched version
- **Instruction 1**: Rollback to the original version

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/mainnet/2025-12-01-upgrade-bridge-and-rollback
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Verify the Proposal

#### 3.1. Verify Instruction 1 (BPF Loader Upgradeable - Upgrade)

**Program ID:**

Verify instruction 1 has program ID: `BPFLoaderUpgradeab1e11111111111111111111111`

**Instruction Data:**

Verify this is the Upgrade instruction (discriminant = 3):

```bash
jq -r '.instructions[0].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output: `03000000`

This is the u32 little-endian representation of 3, which corresponds to the [Upgrade](https://github.com/solana-program/loader-v3/blob/main/program/src/instruction.rs#L223) instruction in BPF Loader Upgradeable.

#### 3.2. Verify Instruction 2 (BPF Loader Upgradeable - Rollback)

**Program ID:**

Verify instruction 2 has program ID: `BPFLoaderUpgradeab1e11111111111111111111111`

**Instruction Data:**

Verify this is also the Upgrade instruction (discriminant = 3):

```bash
jq -r '.instructions[1].data' proposal.json | base64 -d | xxd -p -c 256
```

Expected output: `03000000`

This rollback instruction uses the same Upgrade discriminant but with a buffer containing the original program bytecode.

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
