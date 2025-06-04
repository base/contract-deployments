# Validation

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
> ### Base Security Council Multisig - Mainnet: `0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`
>
> - Domain Hash: `0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3`
> - Message Hash: `0x0693f70caf333f60a20ad8e44b451bd4cea3d2703016c277d5b0d09ecd3c3638`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Base Security Council Multisig - Mainnet (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xb2462f25a14e413c43e63f6a6d256e11fb0da3733f2efef47b95c348ca164ff7` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from `msg.sender` in order for the task simulation to succeed. Note: The Key might be different as it corresponds to the slot associated with [your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Base Multisig - Mainnet (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## Task State Changes

### Base Security Council Multisig - Mainnet (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `1` <br/>
   **Decoded New Value**: `2` <br/>
   **Meaning**: Increments the nonce <br/>

### System Config (`0x73a79Fab69143498Ed3712e519A88a918e1f4072`)

1. **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
   **Before**: `0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **After**: `0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **Decoded New Value**: `0x78ffe9209dff6fe1c9b6f3efdf996bee60346d0e` <br/>
   **Meaning**: Updates the System Config implementation address <br/>

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `9` <br/>
   **Decoded New Value**: `10` <br/>
   **Meaning**: Increments the nonce <br/>

3. **Key**: `0xe612a2ea19e8e76074e4469448baaa0076a49e88f2aa4915dcf5f8a73bf72c63` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x9855054731540a48b28990b63dcf4f33d8ae46a1][0x4a88dda4a880fe15d81d0ba56d70a2770da4a983f625755eb9c4d7c8de2aa2a2] to 1 (approved by the Base Multisig).

### Base Multisig - Mainnet (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

4. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000016` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000017` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `22` <br/>
   **Decoded New Value**: `23` <br/>
   **Meaning**: Increments the nonce <br/>

5. **Key**: `0x96434cd01eccd775b18be28d6d4ab24f5c5ae955d63d845212994747cc9cd431` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd][0x2c6c1586b686483d280098fc0fa445fdf2c4d1d3dfad1a2aa17aac81d10cef9f] to 1 (approved by the Base Security Council Multisig Multisig).

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
