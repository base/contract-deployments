# Pause Base Bridge

Status: READY TO SIGN

## Description

Updates the partner threshold on Base for [Base Bridge](https://github.com/base/bridge). This updates the required signature count for validating messages.

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
