# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Mainnet State Overrides

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Nested Safe

[For CB Signers] `0x9855054731540A48b28990B63DcF4f33d8AE46A1` (`CB Nested Safe`)
[For OP Signers] `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (`OP Nested Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the owner count to 1 so the transaction simulation can occur.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: This is owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1, so the key can be derived from cast index address 0xca11bde05977b3631167028862be2a173976ca11 2.

- **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Override**: `0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11` <br/>
  **Meaning**: This is owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11, so the key can be derived from cast index address 0x0000000000000000000000000000000000000001 2.

## Mainnet State Changes

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **Meaning**: Nonce increment.

- **Key**: _Needs to be computed_ <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)`

### `0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000f62c15e2f99d4869a925b8f57076cd85335832a2` <br/>
  **After**: Newly deployed `PermissionedDisputeGame` address converted to bytes32 <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0xF62c15e2F99d4869A925B8F57076cD85335832A2` to the newly deployed contract address.
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000c5f3677c3c56db4031ab005a3c9c98e1b79d438e` <br/>
  **After**: Newly deployed `FaultDisputeGame` address converted to bytes32 <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0xc5f3677c3C56DB4031ab005a3C9c98e1B79D438e` to the newly deployed contract address.
  **Verify**: You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

### Nested Safe

[For CB Signers] `0x9855054731540A48b28990B63DcF4f33d8AE46A1` (`CB Nested Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000012` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000013` <br/>
  **Meaning**: Nonce increment.

[For OP Signers] `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (`OP Nested Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000065` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000066` <br/>
  **Meaning**: Nonce increment.

### Signing Address

Nonce increment.
