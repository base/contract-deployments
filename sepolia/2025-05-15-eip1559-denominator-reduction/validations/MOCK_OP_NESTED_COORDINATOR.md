# Validation

This document can be used to validate the inputs and result of the execution of `sign-mock-op-nested-coordinator` command.

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
> ### Signer Safe B - Sepolia: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0xa9c8be78fc18ffc31611ab3383313f508a807a96ff50a0e385980e681092e05e`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### System Config Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### CB Coordinator - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Mock OP Nested - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

- **Key**: `0x553f24f5da896cd48edd08523bced82431a0c53b0bb8cacc0743ce10948d338b` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from msg.sender in order for the task simulation to succeed. Note: The `Key` might be different as it corresponds to the slot associated [with your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).
  
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

### CB Coordinator - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `5` <br/>
   **Decoded New Value**: `6` <br/>
   **Meaning**: Increments the nonce <br/>

3. **Key**: `0x7e443f90c58b35e7206ca7ca116f6cfaf742c79887e3d952c80dcbd0aa405cfe` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets `approvedHashes[0x6af0674791925f767060dd52f7fb20984e8639d8][0xb0a1aaf50a97a55b80f041736fc17bf69547d5c06cadca7ea62da4a3966548be]` to `1`. <br/>

### Mock OP Nested - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

4. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `6` <br/>
   **Decoded New Value**: `7` <br/>
   **Meaning**: Increments the nonce <br/>

### <<ContractName>> (`0xf272670eb55e895584501d564AfEB048bEd26194`)

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
