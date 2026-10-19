# E2E Test: Bump Safe Nonce

Status: READY TO SIGN

## Description

Test task for the signing tool. Not a real task: it exists only on the `test/e2e` branch.

The Zeronet Base multisig calls its own `nonce()` view. Signing changes nothing on chain. If executed,
the only state change is the Safe nonce increment.

## Target

| Contract | Address |
| -- | -- |
| Base multisig (`CB_MULTISIG`) | `0x856611eD7E07D83243b15E93f6321f2df6865852` |

## Sign

From the repository root, with the signing-tool commit under test:

```bash
make sign-task SIGNER_TOOL_COMMIT=<commit>
```

Select this Zeronet task, pick Ledger or Trezor, and sign. Trezor needs `trezorctl` (`pipx install trezor`). Do not send the signature anywhere unless the facilitator is
testing execution.
