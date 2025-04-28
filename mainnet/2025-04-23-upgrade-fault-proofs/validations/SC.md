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
> ### Security Council Safe (`0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd`)
>
> - Domain Hash: `<TODO>`
> - Message Hash: `<TODO>`

## Mainnet State Overrides

### Proxy Admin Owner (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Security Council Safe (`0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd`)

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

### Coordinator Safe (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## Mainnet State Changes

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
  **Meaning**: Nonce increment.

- **Key**: `<TODO>` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `<TODO>` (you should see this in your terminal after the transaction simulation) and `NESTED_SAFE` is `0x9855054731540A48b28990B63DcF4f33d8AE46A1`.

### `0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000e749aa49c3edaf1dcb997ea3dac23dff72bcb826` <br/>
  **After**: `0x0000000000000000000000007344da3a618b86cda67f8260c0cc2027d99f5b49` <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0xe749aa49c3edaf1dcb997ea3dac23dff72bcb826` to `0x7344da3a618b86cda67f8260c0cc2027d99f5b49`.
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000e17d670043c3cdd705a3223b3d89a228a1f07f0f` <br/>
  **After**: `0x000000000000000000000000ab91fb6cef84199145133f75cbd96b8a31f184ed` <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0xe17d670043c3cdd705a3223b3d89a228a1f07f0f` to `0xab91fb6cef84199145133f75cbd96b8a31f184ed`.
  **Verify**: You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

### `0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd` (`Security Council Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Nonce increment.

### `0x9855054731540A48b28990B63DcF4f33d8AE46A1` (`CoordinatorSafe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `<TODO>` <br/>
  **After**: `<TODO>` <br/>
  **Meaning**: Nonce increment.

- **Key**: `<TODO>` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets an approval for this transaction from the signer.
  **Verify**: Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `<TODO>` (you should see this in your terminal after the transaction simulation) and `NESTED_SAFE` is `0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd`.

### Signing Address

Nonce increment.
