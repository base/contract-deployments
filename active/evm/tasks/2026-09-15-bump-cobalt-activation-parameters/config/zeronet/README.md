# Bump Cobalt Activation Parameters

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x8a66d2beda49f48113d1bcc324eb24f0ca186320b515551a12e3777f0b5d8591)

## Description

Updates Zeronet's `ProtocolVersions` registry to:

- delay Cobalt activation from September 16, 2026 at 16:00 UTC to 18:00 UTC; and
- raise the minimum protocol version from v1.3.2 to v1.4.0.

The prerequisite [Cobalt upgrade](https://hoodi.etherscan.io/tx/0xabfb3ed6b24334891957b4f0c22273b06392132288862ca8235b13af0a47d667)
has executed and initialized the registry.

The transaction must execute before September 16, 2026 at 15:00 UTC, when the existing activation
enters its one-hour freeze window.

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
