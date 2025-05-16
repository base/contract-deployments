# Validation

This document can be used to validate the inputs and result of the execution of `sign-mock-op-nested` command.

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
> ### Mock OP Nested - Sepolia: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x7eba4a15ee576a9a3e810780b6bcabc315c574f3a08184a963a1ecb849bf704f`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### System Config Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Mock OP Nested - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

- **Key**: `0xbdc69c7e427970b62fa9575f3df9b068fd76a17d0f677a039970ee010315ea0a` <br/>
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

1. **Key**: `0x82fc8b7c584567d53f1d98535c6d084856ae32ca942be48e7120c22d371038a9` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets `approvedHashes[0x6af0674791925f767060dd52f7fb20984e8639d8][0xa6c9313de83c063ff4e940cea082f3527ff3e92e8727fbfcfefb654509dabd08]` to `1`. <br/>

### Mock OP Nested - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `6` <br/>
   **Decoded New Value**: `7` <br/>
   **Meaning**: Increments the nonce <br/>

### System Config - Sepolia (`0xf272670eb55e895584501d564AfEB048bEd26194`)

3. **Key**: `0x000000000000000000000000000000000000000000000000000000000000006a` <br/>
   **Before**: `0x00000000000000000000000000000000000000000000000000000004000000fa` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000400000032` <br/>
   **Value Type**: (uint32,uint32,uint32,uint32) <br/>
   **Decoded Old Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `4`, eip1559Denominator: `250` <br/>
   **Decoded New Value**: operatorFeeConstant: `0`, operatorFeeScalar: `0`, eip1559Elasticity: `4`, eip1559Denominator: `50` <br/>
   **Meaning**: Sets the eip1559Denominator to 50 <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#43-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
