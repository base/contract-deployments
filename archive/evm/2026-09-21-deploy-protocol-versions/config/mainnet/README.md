# Deploy ProtocolVersions

Status: [EXECUTED](https://etherscan.io/tx/0x8e9ba8e7f997be436e8e7ec30fc09cc13a33e2890cbaf27112512f2577b3e184)

## Description

Deploys and initializes Base mainnet's `ProtocolVersions` proxy with the activation history through
Beryl, Cobalt at ID 12 activating September 30, 2026 at 18:00 UTC, and minimum protocol version
v1.4.1. The proxy admin is transferred to the canonical L1 `ProxyAdmin` before deployment completes.

No existing contracts are upgraded and no ETH moves.

## Deployments

| Contract | Address |
| --- | --- |
| `ProtocolVersions` proxy | `0x7480Afc8D99a5c645c247dB5A1e4a4f440e6e095` |
| `ProtocolVersions` implementation | `0xE01aF68e2cb6c4335b17279393E0D60f6F0406f2` |
