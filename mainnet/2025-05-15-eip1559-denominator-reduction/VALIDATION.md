# Validation for Coinbase Signers

This document can be used to validate the inputs and result of the execution of the EIP-1559 denominator reduction script which you are signing.

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
> - Message Hash: `0xec8524022c8c43daf2a8ec1ed0990e9f9870f2b420278190ac079782c7bd3241`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Incident Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xb2e9994c6b31ed56228de129778956be15269b0c7c0536d91dd4772660ea897a` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from msg.sender in order for the task simulation to succeed.

## Task State Changes

### Incident Multisig - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000003e` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000003f` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `62` <br/>
   **Decoded New Value**: `63` <br/>
   **Meaning**: Increments the nonce <br/>

### SystemConfig - Mainnet (`0x73a79Fab69143498Ed3712e519A88a918e1f4072`)

1. **Key**: `0x000000000000000000000000000000000000000000000000000000000000006a` <br/>
   **Before**: `0x00000000000000000000000000000000000000000000000000000002000000fa` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000200000032` <br/>
   **Value Type**: (uint32,uint32,uint32,uint32) <br/>
   **Decoded Old Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `2`, eip1559Denominator: `250` <br/>
   **Decoded New Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `2`, eip1559Denominator: `50` <br/>
   **Meaning**: Sets the eip1559Denominator to 50 <br/>

### Sender - Mainnet

- Nonce increment for the sender of the simulated transaction.

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
