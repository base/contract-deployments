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

## 3. Deploy and initialize the proxy

The implementation is already recorded in `config/mainnet/addresses.json`. Deploy only the proxy:

```bash
make TASK_NETWORK=mainnet deploy-proxy
```

The script temporarily assigns the Ledger deployer as proxy admin, atomically sets the recorded
implementation and calls `initialize`, then transfers admin to `L1_PROXY_ADMIN`. Its post-checks
verify the final admin, implementation, owner, schedule, minimum protocol version, incident
responder, and schedule commitment.

Do not reuse the earlier uninitialized proxy. This command writes the replacement proxy address and
constructor arguments to `config/mainnet/addresses.json`.

## 4. Verify and commit

```bash
VERIFIER_API_KEY=<key> make TASK_NETWORK=mainnet verify
```

Commit the updated `addresses.json` and proxy broadcast record. No Safe validation files,
signatures, approvals, or separate initialization transaction are required.
