# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-10-24-pause-bridge-base
make deps
```

### 2. Execute pause

```bash
SIGNATURES=AAABBBCCC make execute-pause
```

### 3. (When ready) Execute un-pause

```bash
SIGNATURES=AAABBBCCC make execute-unpause
```
