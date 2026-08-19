# Upgrade TEE Registry to Hinted Nitro Validation

Status: READY TO SIGN

## Transactions

- New `P384Verifier` deployment ([`0x6e42e39FDDdaa54616CB345503e8a1e5E8DcfeCf`](https://hoodi.etherscan.io/address/0x6e42e39FDDdaa54616CB345503e8a1e5E8DcfeCf)): [`0xd55a524666e79d1a00fa060f5e9aee3431d2df2b1248a3282b1a650fe46da7eb`](https://hoodi.etherscan.io/tx/0xd55a524666e79d1a00fa060f5e9aee3431d2df2b1248a3282b1a650fe46da7eb) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))
- New `CertManager` deployment ([`0x2F2A6f0828e456ed928dD3279C1C21e01B3a0d75`](https://hoodi.etherscan.io/address/0x2F2A6f0828e456ed928dD3279C1C21e01B3a0d75)): [`0xb42e32296a6ad378103222532f74ec33f8738448dff1d60806de932d5024d5a1`](https://hoodi.etherscan.io/tx/0xb42e32296a6ad378103222532f74ec33f8738448dff1d60806de932d5024d5a1) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))
- New `NitroValidator` deployment ([`0x03e8867E87219E881b4655664Ed6f404F10C87eb`](https://hoodi.etherscan.io/address/0x03e8867E87219E881b4655664Ed6f404F10C87eb)): [`0xb1e66f3ffa955cdc82c49308edc91eac4ffd7a3140d6fffea517046325319554`](https://hoodi.etherscan.io/tx/0xb1e66f3ffa955cdc82c49308edc91eac4ffd7a3140d6fffea517046325319554) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))

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
