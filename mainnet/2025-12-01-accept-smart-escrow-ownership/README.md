# Accept SmartEscrow Ownership

Status: READY TO SIGN

## Description

This task finalises the `SmartEscrow` ownership transfer that was initiated in [`2025-04-07-init-smart-escrow-ownership-transfer`](https://github.com/base/contract-deployments/blob/main/mainnet/2025-04-07-init-smart-escrow-ownership-transfer/README.md). The pending admin is the L1 `ProxyAdmin` owner Safe (aliased on L2); after the mandatory delay expires we must relay an L1 transaction that calls `AccessControlDefaultAdminRules.acceptDefaultAdminTransfer()` on the SmartEscrow contract (`0xb3C2f9fC2727078EC3A2255410e83BA5B62c5B5f`).

We send this call from the L1 owner Safe by depositing a transaction through the Optimism Portal (`0xbEb5Fc579115071764c7423A4f12eDde41f106Ed`) with the Safe as the sender. The call includes no ETH transfer to SmartEscrow, but the Safe must cover the L2 execution fee (`L2_FEE`).

Environment variables:

- `OWNER_SAFE`: L1 Safe that owns SmartEscrow after acceptance.
- `SMART_ESCROW`: SmartEscrow contract on OP Mainnet.
- `PORTAL`: Optimism Portal on Ethereum mainnet.
- `L2_GAS_LIMIT`: Gas limit forwarded to L2 for `acceptDefaultAdminTransfer`.
- `L2_FEE`: ETH sent to the portal to pay the L2 execution fee (set at runtime).

## Procedure

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

### 2. Install Node.js if needed

First, check if you have node installed

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node

```bash
brew install node
```

## Approving the Update transaction

### 1. Update repo:

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool (NOTE: do not enter the task directory. Run this command from the project's root).

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Be sure to select the correct task user from the list of available users to sign.
After completion, the signer tool can be closed by using Ctrl + C.

### 4. Send the signature to the facilitator
