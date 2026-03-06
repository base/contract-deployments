# Pause Base Bridge

Status: READY TO SIGN

## Description

Updates the partner threshold on Base for [Base Bridge](https://github.com/base/bridge). This updates the required signature count for validating messages.

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

### 1. Install Node.js

First, check if you have node installed

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node

```bash
brew install node
```

### 2. Install bun

First, check if you have bun installed

```bash
bun --version
```

If you see a version output from the above command, you can move on. Otherwise, install bun

```bash
curl -fsSL https://bun.sh/install | bash
```

## Signing Steps

### 1. Run the signer tool

```bash
make sign-task
```

### 2. Open the UI at [http://localhost:3000](http://localhost:3000)

### 3. Send signature to facilitator
