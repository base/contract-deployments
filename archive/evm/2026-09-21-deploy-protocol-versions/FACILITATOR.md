# Deploy ProtocolVersions — Facilitator Guide

This task deploys and initializes the Base mainnet `ProtocolVersions` proxy, then transfers its
admin to the canonical L1 `ProxyAdmin`. Run all commands from this directory and pass
`TASK_NETWORK=mainnet` explicitly.

## 1. Review the configuration

Confirm `config/mainnet/.env`, especially the complete activation history, Cobalt timestamp,
minimum protocol version, and incident responder. Cobalt is upgrade ID 12 and activates on
September 30, 2026 at 18:00 UTC (`1790791200`).

## 2. Install dependencies

```bash
make TASK_NETWORK=mainnet deps
```

## 3. Deploy and initialize

```bash
make TASK_NETWORK=mainnet deploy
```

`deploy` first deploys the implementation with 999,999 optimizer runs. It then deploys the proxy
with 5,000 optimizer runs, temporarily assigns the Ledger deployer as proxy admin, atomically sets
the implementation and calls `initialize`, then transfers admin to `L1_PROXY_ADMIN`. The proxy
post-checks verify the final admin, implementation, owner, schedule, minimum protocol version,
incident responder, and schedule commitment.

The scripts write all addresses and proxy constructor arguments to `config/mainnet/addresses.json`.

## 4. Verify and commit

```bash
VERIFIER_API_KEY=<key> make TASK_NETWORK=mainnet verify
```

Commit the updated `addresses.json` and both broadcast records. No Safe validation files,
signatures, approvals, or separate initialization transaction are required.
