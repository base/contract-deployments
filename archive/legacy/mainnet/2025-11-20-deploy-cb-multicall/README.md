# Deploy CBMulticall to Mainnet and Base

Status: [EXECUTED](https://etherscan.io/tx/0xee77ad0fbda687a02f0dcd62ca9089906b7f5ba22089a22fc76ff8932471e339)
Status: [EXECUTED](https://basescan.org/tx/0x72cde5253bf654c9b706e21fe42f05ce1ab5fdffc6c68c881ecb6c43da27ecbe)

## Description

This task deploys an updated version of the `CBMulticall` contract.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-11-20-deploy-cb-multicall
make deps
```

### 2. Run the script:

```bash
make deploy
```
