# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

## 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-11-03-test-upgrade
make deps
```

## 2. Execute the transaction

```bash
SIGNATURES=AAAABBBBCCCC make execute
```

## 3. Set status in README to `[EXECUTED](tx-link)`

## 4. Check in execution materials
