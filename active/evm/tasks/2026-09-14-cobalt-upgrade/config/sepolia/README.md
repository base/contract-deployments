# Cobalt Upgrade

Status: READY TO SIGN

## Description

Upgrades Sepolia's L1 contracts for the Cobalt hardfork and cuts the TEE registry over to
hinted Nitro validation. One transaction from the ProxyAdmin owner makes six calls:

1. Upgrade and initialize a new `ProtocolVersions` registry, importing Sepolia's hardfork
   activation schedule and scheduling Cobalt for 2026-09-23 18:00:00 UTC. This is the
   registry that dynamic upgrades read from.
2. Upgrade `OptimismPortal2` to the implementation with `EthLockbox` removed.
3. Upgrade `SystemConfig` to the matching implementation, keeping Sepolia's patched
   `MAX_GAS_LIMIT` of 2,000,000,000.
4. Upgrade `DisputeGameFactory` so new dispute games are deployed with `CREATE2`.
5. Register the redeployed `AggregateVerifier` for game type 621, which binds the new
   registry.
6. Upgrade the existing `TEEProverRegistry` proxy from the legacy Nitro verifier
   implementation (v0.5.0) to the hinted Nitro validator implementation (v0.6.1).

No ETH moves. Sepolia has no `EthLockbox` (`ethLockbox()` is already the zero address)
and its ETH is already held by the portal, so removing the lockbox paths changes no
balances. Existing dispute games, the game count, the gas limit, the pause state, and
the TEE registry's owner, manager, signers, proposers, game type, and per-signer image
hashes are all unchanged. The redeployed AggregateVerifier ships a new TEE image hash,
so only pre-registered Cobalt enclaves can prove after this lands.

## Custody

| Role                      | Address                                      |
| ------------------------- | -------------------------------------------- |
| ProxyAdmin owner (2-of-2) | `0x0fe884546476dDd290eC46318785046ef68a0BA9` |
| Coinbase multisig         | `0x646132A1667ca7aD00d36616AFBA1A28116C770A` |
| Security Council          | `0x6AF0674791925f767060Dd52f7fB20984E8639d8` |
| `CertManager` owner       | `0x646132A1667ca7aD00d36616AFBA1A28116C770A` |
| `CertManager` revoker     | `0x8074b32bD7d06C8f27596F3D6fbf867A36eA22a3` |

## Targets

| Contract                   | Address                                      |
| -------------------------- | -------------------------------------------- |
| L1 `ProxyAdmin`            | `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3` |
| `OptimismPortal2` proxy    | `0x49f53e41452C74589E85cA1677426Ba426459e85` |
| `SystemConfig` proxy       | `0xf272670eb55e895584501d564AfEB048bEd26194` |
| `DisputeGameFactory` proxy | `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` |
| `TEEProverRegistry` proxy  | `0xf0d7E15673fBA052e83d7f2b26BB6071E86b972e` |

New implementation addresses are recorded in [`addresses.json`](addresses.json) once deployed.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task, sign, and send the signature to the facilitator.
