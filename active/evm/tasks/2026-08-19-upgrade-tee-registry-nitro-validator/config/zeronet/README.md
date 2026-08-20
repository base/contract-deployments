# Upgrade TEE Registry to Hinted Nitro Validation

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x9bbc381a0aa2ea1d7f918090d3c06f3983ee4d36f1517f7e8c73ea09bdaae393)

## Transactions

- New `P384Verifier` deployment ([`0x6e42e39FDDdaa54616CB345503e8a1e5E8DcfeCf`](https://hoodi.etherscan.io/address/0x6e42e39FDDdaa54616CB345503e8a1e5E8DcfeCf)): [`0xd55a524666e79d1a00fa060f5e9aee3431d2df2b1248a3282b1a650fe46da7eb`](https://hoodi.etherscan.io/tx/0xd55a524666e79d1a00fa060f5e9aee3431d2df2b1248a3282b1a650fe46da7eb) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))
- New `CertManager` deployment ([`0x2F2A6f0828e456ed928dD3279C1C21e01B3a0d75`](https://hoodi.etherscan.io/address/0x2F2A6f0828e456ed928dD3279C1C21e01B3a0d75)): [`0xb42e32296a6ad378103222532f74ec33f8738448dff1d60806de932d5024d5a1`](https://hoodi.etherscan.io/tx/0xb42e32296a6ad378103222532f74ec33f8738448dff1d60806de932d5024d5a1) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))
- New `NitroValidator` deployment ([`0x03e8867E87219E881b4655664Ed6f404F10C87eb`](https://hoodi.etherscan.io/address/0x03e8867E87219E881b4655664Ed6f404F10C87eb)): [`0xb1e66f3ffa955cdc82c49308edc91eac4ffd7a3140d6fffea517046325319554`](https://hoodi.etherscan.io/tx/0xb1e66f3ffa955cdc82c49308edc91eac4ffd7a3140d6fffea517046325319554) (artefact: [run-1787156234845.json](../../records/DeployNitroValidatorStack.s.sol/560048/run-1787156234845.json))
- New `TEEProverRegistry` implementation deployment ([`0x2729B7Cb3513306C27F2732A06a87c5Fcf80dc8a`](https://hoodi.etherscan.io/address/0x2729B7Cb3513306C27F2732A06a87c5Fcf80dc8a)): [`0x150942f904412bd705a56408e350bdddcec10ea477d89786a37985d2ee6566a3`](https://hoodi.etherscan.io/tx/0x150942f904412bd705a56408e350bdddcec10ea477d89786a37985d2ee6566a3) (artefact: [run-1787157386323.json](../../records/DeployTEEProverRegistryImpl.s.sol/560048/run-1787157386323.json))
- Coinbase Multisig approval ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0xe30edfd95822aa735352bc75f7d3aad158f8556634d8a3347148a071ea81343e`](https://hoodi.etherscan.io/tx/0xe30edfd95822aa735352bc75f7d3aad158f8556634d8a3347148a071ea81343e) (artefact: [run-1787175280444.json](../../records/SetTEEProverRegistryImpl.s.sol/560048/run-1787175280444.json))
- Security Council approval ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0x6ac1bd5e1209f851d9132b687522c83fad9237399453b659411193a10852fd79`](https://hoodi.etherscan.io/tx/0x6ac1bd5e1209f851d9132b687522c83fad9237399453b659411193a10852fd79) (artefact: [run-1787175385343.json](../../records/SetTEEProverRegistryImpl.s.sol/560048/run-1787175385343.json))
- Execute via Proxy Admin Owner ([`0x3d59999977e0896ee1f8783bB8251DF16fb483E9`](https://hoodi.etherscan.io/address/0x3d59999977e0896ee1f8783bB8251DF16fb483E9)): [`0x9bbc381a0aa2ea1d7f918090d3c06f3983ee4d36f1517f7e8c73ea09bdaae393`](https://hoodi.etherscan.io/tx/0x9bbc381a0aa2ea1d7f918090d3c06f3983ee4d36f1517f7e8c73ea09bdaae393) (artefact: [run-1787175698595.json](../../records/SetTEEProverRegistryImpl.s.sol/560048/run-1787175698595.json))

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
