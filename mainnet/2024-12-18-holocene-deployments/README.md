# Deploy Holocene contracts

## Objective

To support the Holocene Network Upgrade, we need to deploy the latest version of the following contracts:

- [FaultDisputeGame](https://github.com/ethereum-optimism/optimism/blob/dff5f16c510e7f44f1be0574372ccb08bfec045c/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol)
- [PermissionedDisputeGame](https://github.com/ethereum-optimism/optimism/blob/dff5f16c510e7f44f1be0574372ccb08bfec045c/packages/contracts-bedrock/src/dispute/PermissionedDisputeGame.sol)

## Deploying the contracts

### 1. Update repo and move to the appropriate folder:

```
cd contract-deployments
git pull
cd mainnet/2024-12-18-holocene-deployments
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Deploy the contracts

```
make deploy
```
