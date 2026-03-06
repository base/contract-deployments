# Pause SuperchainConfig

Status: READY TO SIGN

## Description

Pauses deposits/withdrawals Base.

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
