# Upgrade OptimismPortal2

Status: READY TO SIGN

## Description

Upgrades Base mainnet's `OptimismPortal2` from `6.0.0` to `7.0.1`.

The transaction is a single `ProxyAdmin.upgrade` call. No storage changes and no ETH moves.

## Targets

| Contract | Address |
| -- | -- |
| `OptimismPortal2` proxy | `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e` |
| `ProxyAdmin` | `0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E` |
| Current implementation (`6.0.0`) | `0xcA5ca23502eFf4254bc11Ac0bEC4Dbb7495Bd06C` |
| New implementation (`7.0.1`) | `TBD` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this mainnet task, sign, and send the signature to the facilitator.
