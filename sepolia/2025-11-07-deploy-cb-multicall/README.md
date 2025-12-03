# Deploy CBMulticall

Status: [EXECUTED](https://sepolia.basescan.org/tx/0x636f737cc8ca52789b65b1e9a9f6111348e80a145eb3e60f1f28d0e0627295c1)

## Description

This task deploys the CBMulticall contract.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-11-07-deploy-cb-multicall
make deps
```

### 2. Run the script:

```bash
make deploy
```
