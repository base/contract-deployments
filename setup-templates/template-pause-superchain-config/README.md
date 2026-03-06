# Pause SuperchainConfig

Status: READY TO SIGN

## Description

Pauses deposits/withdrawals Base.

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

## Sign Pause Task

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd <network>/<task-name>
make deps
```

### 2. Sign pause transactions

```bash
make sign-pause
```

This will output your signature batch to a `signatures-pause.txt` file.

### 3. Send the contents of `signatures-pause.txt` to facilitator
