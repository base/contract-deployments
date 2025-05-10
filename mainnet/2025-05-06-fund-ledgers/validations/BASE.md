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
> - Domain Hash: `0x5792ef80ba481190352d80c47de510c8f6fd2d0ba59c99e91fde9ff4bb0897d9`
> - Message Hash: `0x843fed941bb381f32fbb60cd8c27b2fdb55c16df938ef3232849be7bdcefbc64`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Incident Multisig - Base Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets the owner count to 1 so the transaction simulation can occur.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Adds the Multicall3 as an owner of the Multisig (Multicall3 -> SENTINEL_OWNERS). The key can be derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.

- **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Override**: `0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11` <br/>
  **Meaning**: Adds the Multicall3 as an owner of the Multisig (SENTINEL_OWNERS -> Multicall3). The key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

## Task State Changes

### Incident Multisig - Base Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Increments the nonce <br/>

1. **Balance**: <br/>
   **Before**: `2987232538274778295` <br/>
   **After**: `2587232538274778295` <br/>
   **Decoded Old Value**: `2.987232538274778295 ETH` <br/>
   **Decoded New Value**: `2.587232538274778295 ETH` <br/>
   **Meaning**: Decreases the balance of the Multisig by 0.4 ETH. <br/>

### Ledger - Mainnet (`0x24c3AE1AeDB8142D32BB6d3B988f5910F272D53b`)

2. **Balance**: <br/>
   **Before**: `0` <br/>
   **After**: `100000000000000000` <br/>
   **Decoded Old Value**: `0.0 ETH` <br/>
   **Decoded New Value**: `0.1 ETH` <br/>
   **Meaning**: Increases the balance of the Ledger by 1.0 ETH. <br/>

### Ledger - Mainnet (`0x644e3DedB0e4F83Bfcf8F9992964d240224B74dc`)

3. **Balance**: <br/>
   **Before**: `0` <br/>
   **After**: `100000000000000000` <br/>
   **Decoded Old Value**: `0.0 ETH` <br/>
   **Decoded New Value**: `.1 ETH` <br/>
   **Meaning**: Increases the balance of the Ledger by 1.0 ETH. <br/>

### Ledger - Mainnet (`0x7Ad8E6B7B1f6D66F49559f20053Cef8a7b6c488E`)

4. **Balance**: <br/>
   **Before**: `0` <br/>
   **After**: `100000000000000000` <br/>
   **Decoded Old Value**: `0.0 ETH` <br/>
   **Decoded New Value**: `0.1 ETH` <br/>
   **Meaning**: Increases the balance of the Ledger by 1.0 ETH. <br/>

### Ledger - Mainnet (`0x9bF96DCf51959915c8c343a3E50820Ad069A1859`)

5. **Balance**: <br/>
   **Before**: `10000000000000000` <br/>
   **After**: `110000000000000000` <br/>
   **Decoded Old Value**: `0.01 ETH` <br/>
   **Decoded New Value**: `0.11 ETH` <br/>
   **Meaning**: Increases the balance of the Ledger by 1.0 ETH. <br/>

### Ledger - Mainnet (`0x969ffD102fbF304d4e401999333FE9397DaC653D`)

- Nonce increment for the sender of the simulated transaction.

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
