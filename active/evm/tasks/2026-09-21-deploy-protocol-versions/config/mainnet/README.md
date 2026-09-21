# Deploy ProtocolVersions

Status: READY TO SIGN

## Description

Deploys and initializes Base mainnet's `ProtocolVersions` registry with the activation history
through Beryl, Cobalt at ID 12 activating September 30, 2026 at 18:00 UTC, and minimum protocol
version v1.4.1.

No existing contracts are upgraded and no ETH moves.

## Sign

From the repository root:

```bash
make sign-task
```

Select this mainnet task, sign, and send the signature to the facilitator.
