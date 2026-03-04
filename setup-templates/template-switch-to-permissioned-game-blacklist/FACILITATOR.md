# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/TODO
make deps
```

### 2. Approve upgrade

```bash
SIGNATURES=AAABBBCCC make approve-op
```

### 3. Execute upgrade

```bash
SIGNATURES=AAABBBCCC make execute
```
