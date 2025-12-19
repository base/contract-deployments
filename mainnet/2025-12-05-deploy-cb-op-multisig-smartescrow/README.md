# Deploy New CB and OP MultiSig for SmartEscrow

Status: READY TO SIGN

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-12-05-deploy-cb-op-multisig-smartescrow
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Run relevant script(s)

#### 3.1 Deploy new Safes

```bash
make safe-deps
```

```bash
make deploy
```

This will output the new addresses of the new `Safe` contract to an `addresses.json` file. You will need to commit this file to the repo.
