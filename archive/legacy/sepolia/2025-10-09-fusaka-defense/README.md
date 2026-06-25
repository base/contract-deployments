# Upgrade Fault Proofs

Status: EXECUTED (https://sepolia.etherscan.io/tx/0x7881a472e6153e5c3757254dcf1e924d036bf46af008df496b9ef66ceb6c9535)

## Description

This task contains two scripts. One for deploying new versions of the `FaultDisputeGame` and `PermissionedDisputeGame` contracts, and one for updating the `DisputeGameFactory` contract to reference the new dispute game contracts.

## Sign Task

### 1. Run the signer tool

```bash
make sign-task
```

### 2. Open the UI at [http://localhost:3000](http://localhost:3000)

### 3. Send signature to facilitator
