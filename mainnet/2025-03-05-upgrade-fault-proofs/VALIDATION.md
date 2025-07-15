# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### CB Signers
>
> - Domain Hash: `0x88aac3dc27cc1618ec43a87b3df21482acd24d172027ba3fbb5a5e625d895a0b`
> - Message Hash: `0x9ef8cce91c002602265fd0d330b1295dc002966e87cd9dc90e2a76efef2517dc`
>
> ### OP Signers
>
> - Domain Hash: `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0xc7991c24a74ab490b5fc16fb1ed3b21d1b2feea08a1caa0cf35e2da0be256303`

## Expected Nested Hash

`0x327dcf25f029c9623dbd799635f384b0c63acfcdeb2bded32fde3ebc6c878f0d`

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

#### For CB Signers

- **Key**: `0x8cb5f50dcfb02589430ed0b4a4f27b2874c87b778dee6e2a74b223075947171c` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)`

#### For OP Signers

- **Key**: `0xf248e3d2bff4db2695f9a01b649a5d616c363e8f02c966a13778d0c4e7047c67` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)`

### `0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000f62c15e2f99d4869a925b8f57076cd85335832a2` <br/>
  **After**: `0x0000000000000000000000008cf5972cedf63b099406b3e7da81566885453d8e` <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0xF62c15e2F99d4869A925B8F57076cD85335832A2` to `0x8cf5972cedf63b099406b3e7da81566885453d8e`.
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000c5f3677c3c56db4031ab005a3c9c98e1b79d438e` <br/>
  **After**: `0x000000000000000000000000fe884b822eddb5864e86626e088120c73c0a4364` <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0xc5f3677c3C56DB4031ab005a3C9c98e1B79D438e` to `0xfe884b822eddb5864e86626e088120c73c0a4364`.
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
