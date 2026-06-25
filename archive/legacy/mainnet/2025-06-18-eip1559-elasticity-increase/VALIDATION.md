# Validation for Coinbase Signers

This document can be used to validate the inputs and result of the execution of the EIP-1559 elasticity increase and Gas Limit increase script which you are signing.

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
> ### Incident Multisig - Mainnet: `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`
>
> - Domain Hash: `0xf3474c66ee08325b410c3f442c878d01ec97dd55a415a307e9d7d2ea24336289`
> - Message Hash: `0xa7fc708fdbaa8af29e5c1137193cf5d59c45d4634b587ff9e227b0cec8c5cdda`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Incident Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xf1be6768d6f798cc122f889ccdbd55074910d6f15fb6c82e2473ee7a9a461239` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from `msg.sender` in order for the task simulation to succeed. Note: The Key might be different as it corresponds to the slot associated with [your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69)

## Task State Changes

### Incident Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000040` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000041` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `64` <br/>
   **Decoded New Value**: `65` <br/>
   **Meaning**: Increments the nonce <br/>

### SystemConfig - Mainnet (`0x73a79Fab69143498Ed3712e519A88a918e1f4072`)

-  **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068` <br/>
   **Before**: `0x0000000000000000000000000000000000101c12000008dd0000000008583b00` <br/>
   **After**: `0x0000000000000000000000000000000000101c12000008dd0000000008f0d180` <br/>
   **Value Type**: (uint32,uint32,uint64) <br/>
   **Decoded Old Value**: blobbasefeeScalar: `1055762`, operatorFeeScalar: `2269`, gasLimit: `140000000` <br/>
   **Decoded New Value**: blobbasefeeScalar: `1055762`, operatorFeeScalar: `2269`, gasLimit: `150000000` <br/>
   **Meaning**: Sets the gasLimit to 150000000 <br/>

-  **Key**: `0x000000000000000000000000000000000000000000000000000000000000006a` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000200000032` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000300000032` <br/>
   **Value Type**: (uint32,uint32,uint32,uint32) <br/>
   **Decoded Old Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `2`, eip1559Denominator: `50` <br/>
   **Decoded New Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `3`, eip1559Denominator: `50` <br/>
   **Meaning**: Sets the eip1559Elasticity to 3 <br/>

### Sender - Mainnet

- Nonce increment for the sender of the simulated transaction.

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
