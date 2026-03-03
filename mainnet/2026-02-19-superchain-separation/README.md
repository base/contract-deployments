# Mainnet OP Stack Separation

Status: EXECUTED

[UpdateProxyAdminOwnerSigners](https://etherscan.io/tx/0x00de17d8f1f65c5baa6cfb5ea313309ac6be1ca858035c5a4956727e7ff357e3)
[UpdateCBSafeSigners](https://etherscan.io/tx/0x17d10687b8d9e0f7ce68b65e5cbc23bbceb7ac494a99746a6a2f979cd7206e4f)
[UpgradeSystemConfig](https://etherscan.io/tx/0xa2dc938704977d2f3d0765832e79e1239d97aa6912efadc21a9705ef7dca42eb)
[UpgradeFeeDisburser](https://etherscan.io/tx/0xdc700942c3b4e05e2ee2f6519cb8ed4e5ff626dc70f48c91931b1b3f3593f5b6)
[TerminateSmartEscrow](https://optimistic.etherscan.io/tx/0x75ddb1f30d7fc14a4cea7ab7364cf34001b01863fee954c239564dbcfacbb178)
WithdrawSmartEscrow: PENDING
[AddSecurityCouncilSigner](https://etherscan.io/tx/0x117b78c970396446c891ba82439351555c537f04d0d90222a9d523975bfe599b)

## Description

This task executes our migration away from the shared Superchain configuration to a Base-owned configuration. Each signer profile must produce multiple signatures, so you will repeat the signing steps in the signer tool for each part until all parts are complete.

The number of signatures required per signer profile:

| Signer Profile             | Parts        |
| -------------------------- | ------------ |
| Coinbase Signer            | 6 (part 1–6) |
| Security Council Signer    | 4 (part 1–4) |
| Optimism Signer            | 1            |
| Optimism OP Mainnet Signer | 1            |

## Procedure

### Install dependencies

#### 1. Update foundry

```bash
foundryup
```

#### 2. Install Node.js if needed

First, check if you have node installed:

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node:

```bash
brew install node
```

### Approve the transaction

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run the signing tool

```bash
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- Complete the signature for the current part (e.g., part 1).
- Repeat steps 2–3 for each subsequent part (part 2, part 3, … part N) until all parts have been signed.
- After all parts are complete, close the signer tool with `Ctrl + C`.

#### 4. Send signatures to facilitator

Copy the signature outputs for all parts and send them to the designated facilitator via the agreed communication channel. The facilitator will collect all signatures and execute the transactions.

For facilitator instructions, see [FACILITATORS.md](./FACILITATORS.md).
