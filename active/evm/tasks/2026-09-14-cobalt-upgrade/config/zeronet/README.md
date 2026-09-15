# Cobalt Upgrade

Status: READY TO SIGN

## Description

Upgrades Zeronet's L1 contracts for the Cobalt hardfork. One transaction from the ProxyAdmin owner
makes five calls:

1. Upgrade and initialize a new `ProtocolVersions` registry, importing Zeronet's hardfork activation
   schedule and scheduling Cobalt for 2026-09-16 16:00:00 UTC. This is the registry that dynamic
   upgrades read from.
2. Upgrade `OptimismPortal2` to the implementation with `EthLockbox` removed.
3. Upgrade `SystemConfig` to the matching implementation, keeping Zeronet's patched
   `MAX_GAS_LIMIT` of 2,000,000,000.
4. Upgrade `DisputeGameFactory` so new dispute games are deployed with `CREATE2`.
5. Register the redeployed `AggregateVerifier` for game type 621, which binds the new registry.

No ETH moves. Zeronet has no `EthLockbox` (`ethLockbox()` is already the zero address) and its ETH
is already held by the portal, so removing the lockbox paths changes no balances. Existing dispute
games, the game count, the gas limit, and the pause state are all unchanged, and the transaction
asserts each of these before and after.

## Custody

| Role | Address |
| -- | -- |
| ProxyAdmin owner (2-of-2) | `0x3d59999977e0896ee1f8783bB8251DF16fb483E9` |
| Coinbase multisig | `0x856611eD7E07D83243b15E93f6321f2df6865852` |
| Security Council | `0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA` |

## Targets

| Contract | Address |
| -- | -- |
| L1 `ProxyAdmin` | `0xF2d2c097bE80Fb87844b7E259ef67EFb98b26F87` |
| `OptimismPortal2` proxy | `0x7E3b97C95c823f385Ff6770411F6E12F8E09AC9b` |
| `SystemConfig` proxy | `0x0a111C7980152BDe41D71f48e2E1d8184f5F6187` |
| `DisputeGameFactory` proxy | `0xd930E0CebD52d7C77b8f900De242e818506C5474` |

New implementation addresses are recorded in [`addresses.json`](addresses.json) once deployed.

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
