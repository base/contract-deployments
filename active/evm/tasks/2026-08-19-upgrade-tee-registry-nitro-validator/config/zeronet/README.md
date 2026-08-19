# Upgrade TEE Registry to Hinted Nitro Validation

Status: READY TO SIGN

## Description

Deploy the hinted Nitro validator stack and upgrade the existing `TEEProverRegistry` proxy to an implementation that validates registrations through it.

The registry proxy and all existing signer, proposer, owner, manager, game type, and image-hash storage remain unchanged.

## Custody

| Role | Address |
| -- | -- |
| `CertManager` owner | `0x856611eD7E07D83243b15E93f6321f2df6865852` |
| `CertManager` revoker | `0x5F109182a097c40Cc936742be4B55c1A08aC4dd9` |
| ProxyAdmin owner | `0x3d59999977e0896ee1f8783bB8251DF16fb483E9` |
| TEE registry proxy | `0xc5555440ACa82225E98c2E9cD9c3921c96f42205` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Zeronet task and sign both the forward and rollback transactions. Send the signatures to the facilitator.
