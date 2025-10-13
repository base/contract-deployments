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

### 3. Review the proposal

The Facilitator will provide you with the proposal details. Review:
- New signers list: `MCM_NEW_SIGNERS`
- Signer groups configuration: `MCM_SIGNER_GROUPS`
- Group quorums: `MCM_GROUP_QUORUMS`
- Group parents: `MCM_GROUP_PARENTS`
- MCM Program ID: `MCM_PROGRAM_ID`
- Valid until timestamp: `MCM_VALID_UNTIL`

These values are in the `.env` file and the generated proposal file.

### 4. Sign the proposal

```bash
make mcm-sign
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
