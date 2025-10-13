# Deploy MCM on Devnet Alpha

Status: PENDING

## Description

This task deploys the Multi-Chain Multisig (MCM) program on Solana Devnet (Alpha environment), initializes the multisig instance, configures the initial signers, and transfers ownership of the MCM program to the MCM authority.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/devnet-alpha/2025-10-10-deploy-mcm
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The **Ethereum application** needs to be opened on Ledger with the message "Application is ready".

### 3. Review the proposal

The Facilitator will provide you with the proposal details. Review:
- MCM Program ID: `MCM_PROGRAM_ID`
- MCM Multisig ID: `MCM_MULTISIG_ID`
- MCM Authority (PDA): `MCM_AUTHORITY`
- Initial signers: `MCM_SIGNERS`
- Signer configuration: `MCM_SIGNER_GROUPS`, `MCM_GROUP_QUORUMS`, `MCM_GROUP_PARENTS`
- Valid until timestamp: `MCM_VALID_UNTIL`

These values are in the `.env` file and the generated `accept_ownership_proposal.json`.

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

See [FACILITATORS.md](./FACILITATORS.md) for complete instructions on deploying, configuring, and verifying this task.
