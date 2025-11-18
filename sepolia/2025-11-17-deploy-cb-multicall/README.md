# Deploy CBMulticall

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xddcc4a1b20e45474a09c9a17c008f050c3f278cbde7309bf65be09491b45be18)

## Description

This task deploys an updated version of the `CBMulticall` contract.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-11-17-deploy-cb-multicall
make deps
```

### 2. Run the script:

```bash
make deploy
```
