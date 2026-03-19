# Deploy Proxy Admin (Nested Safe Ownership)

Status: DRAFT

## Overview

Deploys a nested 3-Safe ownership structure to serve as the `proxyAdminOwner` on Zedinet (Hoodi testnet, L1 chain ID 560048).

Structure:
- **SafeA** — 3-of-13 multisig (individual signers)
- **SafeB** — 1-of-13 multisig (same individual signers)
- **SafeC** — 2-of-2 multisig owned by SafeA and SafeB

SafeC becomes the `proxyAdminOwner` / `l1ProxyAdminOwner`.

## Procedure

### 1. Update repo and install dependencies

```bash
cd contract-deployments
git pull
cd zedinet/2026-03-19-deploy-proxy-admin
make deps
```

### 2. Configure environment

Ensure the following variables are set (in `zedinet/.env` or a local `.env`):

```
L1_GNOSIS_SAFE_IMPLEMENTATION=<address>
L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER=<address>
SAFE_PROXY_FACTORY=<address>
```

### 3. Verify `addresses.json`

Confirm that `addresses.json` contains exactly 13 owner addresses:

```json
{
  "owners": ["0x...", ...]
}
```

### 4. Deploy the Safes

```bash
make deploy
```

This will deploy SafeA, SafeB, and SafeC onchain and write their addresses to `deployed-addresses.json`. Commit this file to the repo.

### 5. Update `zedinet/.env`

After deployment, populate the following variables in `zedinet/.env` with the SafeC address from `deployed-addresses.json`:

```
BASE_SECURITY_COUNCIL=<SafeC address>
CB_COORDINATOR_MULTISIG=<SafeC address>
CB_MULTISIG=<SafeC address>
INCIDENT_MULTISIG=<SafeC address>
OP_MULTISIG=<SafeC address>
PROXY_ADMIN_OWNER=<SafeC address>
```
