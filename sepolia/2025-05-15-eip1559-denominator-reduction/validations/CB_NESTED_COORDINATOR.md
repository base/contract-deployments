# Validation

This document can be used to validate the inputs and result of the execution of `sign-mock-cb-nested-coordinator` command.

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
> ### CB Nested - Sepolia: `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`
>
> - Domain Hash: `0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23`
> - Message Hash: `0xeb4fd8cd515683c5f3e5badc0d3365152e273be1ffeeede650cabc128e61a4ab`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### System Config Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### CB Nested - Sepolia (`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x15da65abea640207b3ada02d3004196783015f1090bb5158ea37ea41b7d1d1ff` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from msg.sender in order for the task simulation to succeed. Note: The `Key` might be different as it corresponds to the slot associated [with your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).

### CB Coordinator - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## Task State Changes

### System Config Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000016` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000017` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `22` <br/>
   **Decoded New Value**: `23` <br/>
   **Meaning**: Increments the nonce <br/>

1. **Key**: `0xb8617d913ec0184dd931b7d503813c9c8463303c5537bbf5c834bd7267c0f86c` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets `approvedHashes[0x646132a1667ca7ad00d36616afba1a28116c770a][0xa6c9313de83c063ff4e940cea082f3527ff3e92e8727fbfcfefb654509dabd08]` to `1`. <br/>

### CB Nested - Sepolia(`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `2` <br/>
   **Decoded New Value**: `3` <br/>
   **Meaning**: Increments the nonce <br/>

### CB Coordinator - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

3. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `5` <br/>
   **Decoded New Value**: `6` <br/>
   **Meaning**: Increments the nonce <br/>

4. **Key**: `0xf02ac180c9d9d43593598594486821f3f3a7b3da70582919e670116326e46954` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets `approvedHashes[0x5dfeb066334b67355a15dc9b67317fd2a2e1f77f][0xb0a1aaf50a97a55b80f041736fc17bf69547d5c06cadca7ea62da4a3966548be]` to `1`. <br/>

### System Config - Sepolia (`0xf272670eb55e895584501d564AfEB048bEd26194`)

5. **Key**: `0x000000000000000000000000000000000000000000000000000000000000006a` <br/>
   **Before**: `0x00000000000000000000000000000000000000000000000000000004000000fa` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000400000032` <br/>
   **Value Type**: (uint32,uint32,uint32,uint32) <br/>
   **Decoded Old Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `4`, eip1559Denominator: `250` <br/>
   **Decoded New Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `4`, eip1559Denominator: `50` <br/>
   **Meaning**: Sets the eip1559Denominator to 50 <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#43-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
