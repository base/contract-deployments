# Cobalt Upgrade

Status: READY TO SIGN

## Description

Upgrades Base mainnet's L1 contracts for Cobalt and cuts the TEE registry over to hinted Nitro
validation. The transaction:

1. Raises the `ProtocolVersions` minimum protocol version from v1.4.1 to v1.4.2.
2. Upgrades `OptimismPortal2`, `SystemConfig`, and `DisputeGameFactory`.
3. Registers the Cobalt `AggregateVerifier`, bound to the initialized `ProtocolVersions` registry.
4. Upgrades `TEEProverRegistry` to the hinted Nitro implementation.

The separately deployed registry already schedules Cobalt for September 30, 2026 at 18:00 UTC and
this transaction does not change that timestamp. No ETH moves.

`make TASK_NETWORK=mainnet deploy` deploys the Cobalt implementations first, followed by the Nitro
validator stack and hinted `TEEProverRegistry` implementation.

## Sign

From the repository root:

```bash
git fetch origin
git pull
make sign-task
```

Select this mainnet task, sign, and send the signature to the facilitator.
