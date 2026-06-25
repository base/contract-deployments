# Deploy CBMulticall

Status: [EXECUTED](https://basescan.org/tx/0xd4d5787e62ee6a6bb8988a43fd8cbbc7f44861df4e66108e396491286cebdafb)

## Description

This task deploys the CBMulticall contract.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-11-15-deploy-cb-multicall
make deps
```

### 2. Run the script:

```bash
make deploy
```
