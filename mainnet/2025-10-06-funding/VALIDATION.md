# Validation for Coinbase Signers

This document can be used to validate the inputs and result of the execution of the funding transaction which you are signing.

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
> - Domain Hash: `0xf3474c66ee08325b410c3f442c878d01ec97dd55a415a307e9d7d2ea24336289`
> - Message Hash: `0x92edce5c578c4a01a764572285214e8de98a08bc308f043d09585a7a22d8d2cc`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xad4b97ba141f949a3ffd85b17607d2d1c8644516be3250fa7eca7a4ae89d857f` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Hashes the transaction data together with the signer address, and writes 1 into approvedHashes[signer][hash], in order to simulate that the approveHash has already been called.

## Task State Changes

### Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000005a` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000005b` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `90` <br/>
   **Decoded New Value**: `91` <br/>
   **Meaning**: Increments the nonce <br/>

1. **Balance**: <br/>
   **Before**: `2895600671558404283` <br/>
   **After**: `1895600671558404283` <br/>
   **Decoded Old Value**: `2.895600671558404283 ETH` <br/>
   **Decoded New Value**: `1.895600671558404283 ETH` <br/>
   **Meaning**: Decreases the balance of the Multisig by 1 ETH. <br/>

### Ledger - Mainnet (`0x1841CB3C2ce6870D0417844C817849da64E6e937`)

2. **Balance**: <br/>
   **Before**: `0` <br/>
   **After**: `1.000000000000000000` <br/>
   **Decoded Old Value**: `0 ETH` <br/>
   **Decoded New Value**: `1.000000000000000000 ETH` <br/>
   **Meaning**: Increases the balance of the Ledger by 1.0 ETH. <br/>

- Nonce increment for the sender of the simulated transaction.

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
