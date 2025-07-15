# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Sepolia State Overrides

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Nested Safe

[For CB Signers] `0x646132A1667ca7aD00d36616AFBA1A28116C770A` (`CB Nested Safe`)

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

## Sepolia State Changes

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000012` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000013` <br/>
  **Meaning**: Nonce increment.

#### For CB Signers

- **Key**: `0xb8af1766c34180f8ca25988586bcc2d31b0506d064a8da05beb4a6e443b79e71` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)`

### Nested Safe

[For CB Signers] `0x646132A1667ca7aD00d36616AFBA1A28116C770A` (`CB Nested Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Nonce increment.

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000cca6a4916fa6de5d671cc77760a3b10b012cca16` <br/>
  **After**: `0x00000000000000000000000058d465e2e31b811fdbbe5461627a0a88c3c1be2f` <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0xcca6a4916fa6de5d671cc77760a3b10b012cca16` to `0x58d465e2e31b811fdbbe5461627a0a88c3c1be2f`.
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000009cd8b02e84df3ef61db3b34123206568490cb279` <br/>
  **After**: `0x00000000000000000000000076d7f861bbc8cbef20bad1a3f385eb95dd22306b` <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0x9cd8b02e84df3ef61db3b34123206568490cb279` to `0x76d7f861bbc8cbef20bad1a3f385eb95dd22306b`.
  **Verify**: You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

### Signing Address

Nonce increment.
