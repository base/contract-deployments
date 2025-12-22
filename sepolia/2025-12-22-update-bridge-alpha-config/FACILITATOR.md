# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-12-22-update-bridge-alpha-config
make deps
```

### 2. Execute update

```bash
SIGNATURES=AAABBBCCC make execute
```
