# Delay Cobalt Activation to 20:00 UTC

Status: READY TO SIGN

## Description

Delays Zeronet's Cobalt activation from September 16, 2026 at 18:00 UTC to 20:00 UTC using the
`ProtocolVersions` incident responder.

The prerequisite [18:00 UTC delay](https://hoodi.etherscan.io/tx/0x8a66d2beda49f48113d1bcc324eb24f0ca186320b515551a12e3777f0b5d8591)
has executed.

This transaction must execute strictly before September 16, 2026 at 17:00 UTC, when the existing
18:00 UTC activation enters its one-hour freeze window.

## Target

| Contract | Address |
| -- | -- |
| `ProtocolVersions` proxy | `0x30e172aaC675c9fe5A64792F92C9fD4d3E7cA9Da` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task, sign, and send the signature to the facilitator.
