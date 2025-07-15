# Validation for Security Council Signers

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

> [!NOTE]
>
> This document provides names for each contract address to add clarity to what you are seeing. These names will not be visible in the Tenderly UI. All that matters is that addresses and storage slot hex values match exactly what is presented in this document.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council Safe - Mainnet: `0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`
>
> - Domain Hash: `0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3`
> - Message Hash: `0xfb35bb9de829bcf7b4a682ac101da587ee4fbd8a00b678c27cf752645789cc31`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Security Council Safe - Mainnet (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets the owner count to 1 so the transaction simulation can occur.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: This is owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1, so the key can be derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.

- **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Override**: `0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11` <br/>
  **Meaning**: This is owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### CB Coordinator Safe - Mainnet (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## Task State Changes

### Security Council Safe - Mainnet (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Increments the nonce <br/>

### Dispute Game Factory Proxy - Mainnet (`0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e`)

1. **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
   **Before**: `0x000000000000000000000000e749aa49c3edaf1dcb997ea3dac23dff72bcb826` <br/>
   **After**: `0x0000000000000000000000007344da3a618b86cda67f8260c0cc2027d99f5b49` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xE749aA49c3eDAF1DCb997eA3DAC23dff72bcb826` <br/>
   **Decoded New Value**: `0x7344Da3A618b86cdA67f8260C0cc2027D99F5B49` <br/>
   **Meaning**: Updates the `PermissionedDisputeGame` implementation address. You can verify the key derivation by running `cast index uint32 1 101` in your terminal. <br/>

2. **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
   **Before**: `0x000000000000000000000000e17d670043c3cdd705a3223b3d89a228a1f07f0f` <br/>
   **After**: `0x000000000000000000000000ab91fb6cef84199145133f75cbd96b8a31f184ed` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xE17d670043c3cDd705a3223B3D89A228A1f07F0f` <br/>
   **Decoded New Value**: `0xAB91FB6cef84199145133f75cBD96B8a31F184ED` <br/>
   **Meaning**: Updates the `FaultDisputeGame` implementation address. You can verify the key derivation by running `cast index uint32 0 101` in your terminal. <br/>

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

3. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `8` <br/>
   **Decoded New Value**: `9` <br/>
   **Meaning**: Increments the nonce <br/>

4. **Key**: `0xb6dd246ed63451030f1723985e9b9585b536e679783d2a9c70d84aa5a465dcb7` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets an approval for this transaction from the signer. Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `0x378644b143fa5f6becf1f80e7c66ebb76369df458d06f1d2a82ec1cae4124806` (you should see this in your terminal as the Nested hash for safe 0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c) and `NESTED_SAFE` is `0x9855054731540A48b28990B63DcF4f33d8AE46A1`. <br/>

### CB Coordinator Safe - Mainnet (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

5. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000015` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000016` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `21` <br/>
   **Decoded New Value**: `22` <br/>
   **Meaning**: Increments the nonce <br/>

6. **Key**: `0xd44aa84538c38f5f557ad41295befbb0b175c0e64da81611575bb33319b6c9f5` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets an approval for this transaction from the signer. Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `0xbb32860528d49e6103c942c2d7ffeb7d2ff304e1c86cec7c2bc445c3a3921335` (you should see this in your terminal as the Nested hash for safe 0x9855054731540A48b28990B63DcF4f33d8AE46A1) and `NESTED_SAFE` is `0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd`. <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#43-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
