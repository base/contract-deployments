# ETH Recovery Contract Deployment

Status: EXECUTED

## Description

This task deploys an ETH recovery system to recover funds mistakenly sent to the Base portal address on Ethereum mainnet. Users have been sending ETH to the same address (0x49048044D57e1C92A77f79988d21Fa8fAF74E97e) that exists on Ethereum as the Base portal contract.

The deployment consists of two separate phases:

**Phase 1 - Implementation Deployment (via DeployRecoveryImplementation.s.sol)**

> This deployment will be broadcasted and executed onchain directly from this script

- **Command**: `make deploy-implementation RPC_URL=<your-rpc-url>`
- Deploy the Recovery implementation contract from a separate EOA (NOT the DEPLOYER address)

**Phase 2 - Proxy Deployment (via DeployRecoveryProxies.s.sol)**

> This script will NOT broadcast or execute any deployment - it only generates the deployment artifacts that will be consumed by our key management system

- **Command**: `make dry-run-deployments RPC_URL=<your-rpc-url>`
- Generate artifacts for 6 Recovery proxy contract deployments to align the DEPLOYER's nonce
- The first 5 deployments increment the nonce (deploying Recovery proxies allows potential fund recovery from these addresses if needed)
- The 6th deployment will reach the target portal address (0x49048044D57e1C92A77f79988d21Fa8fAF74E97e) where the funds are located

The Recovery contract enables the incident multisig to rescue ETH from any deployed contract address.

## Description

We need to sign recoveries for 3 different chains. Please follow the instructions for each respective chain:

- [Arbitrum](./ARBITRUM_VALIDATION.md)
- [Optimism](./OPTIMISM_VALIDATION.md)

Due to the large number of recoveries for the Base chain, they are split into 5 seperate transactions

- [BASE1](./BASE_VALIDATION.md)
- [BASE2](./BASE_VALIDATION.md)
- [BASE3](./BASE_VALIDATION.md)
- [BASE4](./BASE_VALIDATION.md)
- [BASE5](./BASE_VALIDATION.md)
