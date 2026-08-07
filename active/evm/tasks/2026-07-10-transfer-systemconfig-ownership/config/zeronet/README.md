# Transfer SystemConfig Ownership

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x588703bac3e3c12e546ad2c3bde3042f5e0cf0912358b878da695d4208f4c8cc)

## Description

Transfer the Zeronet `SystemConfig` owner from the proxy admin owner Safe to the incident multisig.

## Addresses

| Role | Address |
| -- | -- |
| `SystemConfig` | `0x0a111C7980152bDe41D71f48e2E1d8184f5f6187` |
| Current owner | `0x3d59999977e0896ee1f8783bB8251DF16fb483E9` |
| New owner | `0x856611ed7e07d83243b15e93f6321f2df6865852` |

## Sign

From the repository root:

```bash
make sign-task
```

Open [http://localhost:3000](http://localhost:3000), select this Zeronet task, sign, and send the signature to the facilitator.
