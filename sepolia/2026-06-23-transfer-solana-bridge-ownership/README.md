# Transfer Base Sepolia Solana Bridge Owner

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xe7e9efe67323840d61bfd4517f3604c0ccde0b1a1f99f305f507c5934593e486)

## Description

This task transfers control of the Base Sepolia Solana bridge contracts from the aliased old
Coinbase L1 multisig to the aliased new Coinbase L1 multisig.

Superchain separation migrated Coinbase upgrade signers to a new multisig address, but these bridge
contracts are still controlled by the old multisig's L2 alias.

| Role | L1 address | L2 alias |
| -- | -- | -- |
| Current owner | [`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`](https://sepolia.etherscan.io/address/0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f) | [`0x6f0fB066334B67355A15dc9b67317fD2a2e20890`](https://sepolia.basescan.org/address/0x6f0fB066334B67355A15dc9b67317fD2a2e20890) |
| New owner | [`0x646132A1667ca7aD00d36616AFBA1A28116C770A`](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A) | [`0x757232A1667ca7aD00d36616AFBA1A28116C881B`](https://sepolia.basescan.org/address/0x757232A1667ca7aD00d36616AFBA1A28116C881B) |

The calls are executed from Sepolia L1 through `OptimismPortal2`, which makes the old L1 multisig's
aliased address transfer ownership of each contract on Base Sepolia. Two ownership mechanisms are
involved:

| Contract | Address | Mechanism |
| -- | -- | -- |
| Bridge | [`0x01824a90d32A69022DdAEcC6C5C14Ed08dB4EB9B`](https://sepolia.basescan.org/address/0x01824a90d32A69022DdAEcC6C5C14Ed08dB4EB9B) | `transferOwnership` + `ERC1967Factory.changeAdmin` |
| TwinBeacon | [`0x11bF22cFf007C46C725Dc59A919383326E3cdefB`](https://sepolia.basescan.org/address/0x11bF22cFf007C46C725Dc59A919383326E3cdefB) | `transferOwnership` |
| CrossChainERC20Beacon | [`0xc039781ccb3cb281f69f8509bfb17163993dd6d1`](https://sepolia.basescan.org/address/0xc039781ccb3cb281f69f8509bfb17163993dd6d1) | `transferOwnership` |
| CrossChainERC20Factory | [`0x488EB7F7cb2568e31595D48cb26F63963Cc7565D`](https://sepolia.basescan.org/address/0x488EB7F7cb2568e31595D48cb26F63963Cc7565D) | `ERC1967Factory.changeAdmin` |
| BridgeValidator | [`0x863Bed3E344035253CC44C75612Ad5fDF5904aEE`](https://sepolia.basescan.org/address/0x863Bed3E344035253CC44C75612Ad5fDF5904aEE) | `ERC1967Factory.changeAdmin` |
| RelayerOrchestrator | [`0x1e0842b2E6FA06A59b05a9c1d36a6480730012CE`](https://sepolia.basescan.org/address/0x1e0842b2E6FA06A59b05a9c1d36a6480730012CE) | `ERC1967Factory.changeAdmin` |

## Approving the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

Run this command from the repo root. Do not enter the task directory.

```bash
make sign-task
```

### 3. Sign

Open [http://localhost:3000](http://localhost:3000) and select:

```text
sepolia/2026-06-23-transfer-solana-bridge-ownership
```

After signing, copy the signature and send it to the facilitator. You may then close the signer
tool with `Ctrl + C`.
