# Pause Base Bridge

Status: READY TO SIGN

## Description

Pauses the Base side of [Base Bridge](https://github.com/base/bridge).

## Task Origin Signing

After setting up the task, generate cryptographic attestations (sigstore bundles) to prove who created and facilitated the task. These signatures are stored in `<network>/signatures/<task-name>/`.

### Task creator (run after task setup):
```bash
make sign-as-task-creator
```

### Base facilitator:
```bash
make sign-as-base-facilitator
```

### Security Council facilitator:
```bash
make sign-as-sc-facilitator
```

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
