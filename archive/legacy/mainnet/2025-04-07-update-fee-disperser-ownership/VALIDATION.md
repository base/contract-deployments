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
> ### CB Signer Safe - Base Mainnet: `0xd94E416cf2c7167608B2515B7e4102B41efff94f`
>
> - Domain Hash: `0xd16e718462d25bb73b8c6aba4611b4bc91c8e12dbf5180f9cd42af8080cffae9`
> - Message Hash: `0x5595fa81192e986455f2270dc4341488deef7151bf5729f7997db641d4a01981`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### CB Signer Safe - Base Mainnet (`0xd94E416cf2c7167608B2515B7e4102B41efff94f`)

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

## Task State Changes

### Fee Dispurser - Base Mainnet (`0x09C7bAD99688a55a2e83644BFAed09e62bDcCcBA`)

0. **Key**: `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103` <br/>
   **Before**: `0x000000000000000000000000d94e416cf2c7167608b2515b7e4102b41efff94f` <br/>
   **After**: `0x000000000000000000000000ad5b57feb77e294fd7bf5ebe9ab01caa0a90b221` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xd94E416cf2c7167608B2515B7e4102B41efff94f` <br/>
   **Decoded New Value**: `0xaD5B57FEB77e294fD7BF5EBE9aB01caA0a90B221` <br/>
   **Meaning**: Updates the proxy admin <br/>

### CB Signer Safe - Base Mainnet (`0xd94E416cf2c7167608B2515B7e4102B41efff94f`)

1. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `9` <br/>
   **Decoded New Value**: `10` <br/>
   **Meaning**: Increments the nonce <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](./README.md/#32-validate-correctness-of-the-state-diff) to continue the signing process.
