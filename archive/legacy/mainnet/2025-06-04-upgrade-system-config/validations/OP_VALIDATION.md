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
> ### OP Multisig - Mainnet: `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
>
> - Domain Hash: `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0xdcbebfee848d6675ec39aeb26a15cd28d2b9c514621bc143854af1a0c7c715a2`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### OP Multisig - Mainnet (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x1c78adc7ff77deba7d0b2df0ec6cdf879453dd4259eadcf28d08d05fef5ad52e` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from `msg.sender` in order for the task simulation to succeed. Note: The Key might be different as it corresponds to the slot associated with [your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).

## Task State Changes

### System Config (`0x73a79Fab69143498Ed3712e519A88a918e1f4072`)

0. **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
   **Before**: `0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **After**: `0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **Decoded New Value**: `0x78ffe9209dff6fe1c9b6f3efdf996bee60346d0e` <br/>
   **Meaning**: Updates the System Config implementation address <br/>

### Proxy Admin Owner - Mainnet (`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`)

1. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `9` <br/>
   **Decoded New Value**: `10` <br/>
   **Meaning**: Increments the nonce <br/>

2. **Key**: `0x2d9dddc7b6b404b6b4d49c7d3bd597c29716b1108262a9a1589c20169d68dd70` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a][0x4a88dda4a880fe15d81d0ba56d70a2770da4a983f625755eb9c4d7c8de2aa2a2] to 1 (approved by the OP Multisig).

### OP Multisig - Mainnet (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)

3. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000006b` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000006c` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `107` <br/>
   **Decoded New Value**: `108` <br/>
   **Meaning**: Increments the nonce <br/>

4. **Key**: `0x1c78adc7ff77deba7d0b2df0ec6cdf879453dd4259eadcf28d08d05fef5ad52e` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `1` <br/>
   **Decoded New Value**: `0` <br/>
   **Meaning**: Artifact of cleaning the approval from `msg.sender` that was set in the state overrides. This state change will NOT be present in the final transaction.

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
