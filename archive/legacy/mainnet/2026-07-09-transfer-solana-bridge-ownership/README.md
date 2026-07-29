# Transfer Base Mainnet Solana Bridge Owner

Status: [EXECUTED](https://etherscan.io/tx/0x3930fbbc44aa0331ec3da944b23112a5ce427cea3192133cdde476ddfe1b804a)

## Description

This task transfers control of the Base mainnet Solana bridge contracts from the aliased old
Coinbase L1 multisig to the aliased new Coinbase L1 multisig.

Superchain separation migrated Coinbase upgrade signers to a new multisig address, but these bridge
contracts are still controlled by the old multisig's L2 alias.

| Role | L1 address | L2 alias |
| -- | -- | -- |
| Current owner | [`0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`](https://etherscan.io/address/0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110) | [`0xaD5B57FEB77e294fD7BF5EBE9aB01caA0a90B221`](https://basescan.org/address/0xaD5B57FEB77e294fD7BF5EBE9aB01caA0a90B221) |
| New owner | [`0x9855054731540A48b28990B63DcF4f33d8AE46A1`](https://etherscan.io/address/0x9855054731540A48b28990B63DcF4f33d8AE46A1) | [`0xa966054731540a48b28990b63Dcf4f33d8aE57B2`](https://basescan.org/address/0xa966054731540a48b28990b63Dcf4f33d8aE57B2) |

The calls are executed from Ethereum mainnet through `OptimismPortal2`, which makes the old L1
multisig's aliased address transfer ownership of each contract on Base. Two ownership mechanisms are
involved:

| Contract | Address | Mechanism |
| -- | -- | -- |
| Bridge | [`0x3eff766C76a1be2Ce1aCF2B69c78bCae257D5188`](https://basescan.org/address/0x3eff766C76a1be2Ce1aCF2B69c78bCae257D5188) | `transferOwnership` + `ERC1967Factory.changeAdmin` |
| TwinBeacon | [`0xb326c02150bb0De265Bb0eCeDA53531ab0163bf6`](https://basescan.org/address/0xb326c02150bb0De265Bb0eCeDA53531ab0163bf6) | `transferOwnership` |
| CrossChainERC20Beacon | [`0xddc41fda4b758728d07f4686dbe7d1c75c6b2552`](https://basescan.org/address/0xddc41fda4b758728d07f4686dbe7d1c75c6b2552) | `transferOwnership` |
| CrossChainERC20Factory | [`0xDD56781d0509650f8C2981231B6C917f2d5d7dF2`](https://basescan.org/address/0xDD56781d0509650f8C2981231B6C917f2d5d7dF2) | `ERC1967Factory.changeAdmin` |
| BridgeValidator | [`0xAF24c1c24Ff3BF1e6D882518120fC25442d6794B`](https://basescan.org/address/0xAF24c1c24Ff3BF1e6D882518120fC25442d6794B) | `ERC1967Factory.changeAdmin` |
| RelayerOrchestrator | [`0x8Cfa6F29930E6310B6074baB0052c14a709B4741`](https://basescan.org/address/0x8Cfa6F29930E6310B6074baB0052c14a709B4741) | `ERC1967Factory.changeAdmin` |

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
mainnet/2026-07-09-transfer-solana-bridge-ownership
```

After signing, copy the signature and send it to the facilitator. You may then close the signer
tool with `Ctrl + C`.
