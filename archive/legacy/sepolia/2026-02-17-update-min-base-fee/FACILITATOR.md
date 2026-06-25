# Facilitator Guide

Guide for facilitators after collecting signatures from signers.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2026-02-17-update-min-base-fee
make deps
```

### 2. Execute upgrade

```bash
SIGNATURES=AAABBBCCC make execute
```

### 3. (**ONLY** if needed) Execute upgrade rollback

> [!IMPORTANT]
> 
> THIS SHOULD ONLY BE PERFORMED IN THE EVENT THAT WE NEED TO ROLLBACK

```bash
SIGNATURES=AAABBBCCC make execute-rollback
```
