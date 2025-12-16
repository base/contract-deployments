# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-12-15-increase-min-base-fee
make deps
```

### 2. Execute upgrade

```bash
SIGNATURES=AAABBBCCC make execute
```
