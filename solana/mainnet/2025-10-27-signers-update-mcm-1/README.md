# Signers Update MCM 1

Status: [EXECUTED](https://explorer.solana.com/tx/3Hch6HsfACH5HBSVJJH8LTPLvE8y8oEkwBgDkBMAWFuUx3YJNzzP2pNtMy2Q5k5HStxeUUFvhtVKezmT5ZTnFqqf?cluster=mainnet)

## Description

This task initializes the signers configuration of the multisig `0x0000000000000000000000000000000000000000000000000000000000000001` managed by the MCM program.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/mainnet/2025-10-27-signers-update-mcm-1
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Sign the proposal

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

### 4. Send signature to Facilitator

Copy the **entire signature** and send it to the Facilitator via your secure communication channel.

**That's it!** The Facilitator will collect all signatures and execute the proposal.

## For Facilitators

See [FACILITATORS.md](./FACILITATORS.md) for complete instructions on preparing, executing, and verifying this task.
