# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

## Execution Order

This task is configured to execute after the gas/elasticity task (nonce 99). The gas/elasticity task must be executed first (nonce 98).

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
