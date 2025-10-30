# MCM Bridge Pause/Unpause

Status: EXECUTED (https://solscan.io/tx/mvDops5iMa5GbeMKsCDGBEhKC1qAZB5ykdCQyTtVM7eED9JQxoC5dxf61dtgKMXLMLB74sT5FBaLbCw5YC3oAuF?cluster=devnet)

Unpause: https://solscan.io/tx/2dV1McFJFkceBdqUqe6Nd2tgVNE5ts8ZBTS2p38fp4mu3DngcpRZCeeNbU2KzNwWUnZ8pY9uUnMEVktqo9CZCLfd?cluster=devnet

## Description

This task pauses or unpauses the Bridge program using the MCM program. This is a critical security operation that can be used to halt bridge operations in emergency situations or resume them after issues are resolved.

## Procedure for Signers

### 1. Update repo

```bash
cd contract-deployments
git pull
cd solana/devnet/2025-10-24-mcm-pause-unpause-bridge
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
