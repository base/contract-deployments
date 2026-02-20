# Pause SuperchainConfig

Status: READY TO SIGN

## Description

Pauses/unpauses the L1 SuperchainConfig contract, which halts OptimismPortal deposits/withdrawals for Base mainnet.

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

### 3. Send all signatures to facilitator
