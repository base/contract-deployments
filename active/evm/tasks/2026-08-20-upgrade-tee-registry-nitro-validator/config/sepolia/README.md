# Upgrade TEE Registry to Hinted Nitro Validation

Status: READY TO SIGN

## Description

Deploy the hinted Nitro validator stack and upgrade the existing `TEEProverRegistry` proxy to an implementation that validates registrations through it.

The registry proxy and all existing signer, proposer, owner, manager, game type, and image-hash storage remain unchanged.

## Custody

| Role | Address |
| -- | -- |
| `CertManager` owner | `0x646132A1667ca7aD00d36616AFBA1A28116C770A` |
| `CertManager` revoker | `0x8074b32bD7d06C8f27596F3D6fbf867A36eA22a3` |
| ProxyAdmin owner | `0x0fe884546476dDd290eC46318785046ef68a0BA9` |
| TEE registry proxy | `0xf0d7E15673fBA052e83d7f2b26BB6071E86b972e` |

## Sign

From the repository root:

```bash
make sign-task
```

Select this Sepolia task and sign both the forward and rollback transactions. Send the signatures to the facilitator.
