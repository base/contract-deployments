# Pause Base Bridge

Status: READY TO SIGN

## Description

Pauses the Base side of [Base Bridge](https://github.com/base/bridge).

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

## Sign Task

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

### 3. Sign unpause transactions

```bash
make sign-unpause
```

### 4. Send all signatures to facilitator
