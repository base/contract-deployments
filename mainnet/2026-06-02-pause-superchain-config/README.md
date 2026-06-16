# Pause SuperchainConfig

Status: SIGNED

## Description

Pauses deposits/withdrawals Base.

## Sign Pause Task

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-02-pause-superchain-config
make deps
```

### 2. Sign pause transactions

```bash
make sign-pause
```

This will output your signature batch to a `signatures-pause.txt` file.

### 3. Send the contents of `signatures-pause.txt` to facilitator
