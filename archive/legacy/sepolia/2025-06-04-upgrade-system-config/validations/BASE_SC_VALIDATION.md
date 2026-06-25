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
> ### Base Security Council Multisig - Sepolia: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x162e3e3614192c09995c2e575e230eede29197c5f344436497cefac155e79602`
# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Proxy Admin Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Base Multisig - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Base Security Council Multisig - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

- **Key**: `0xed56a8e17d5b17ed763270d3db31249f41c143af05268d00dfd1edc65ba1b0b6` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from `msg.sender` in order for the task simulation to succeed. Note: The Key might be different as it corresponds to the slot associated with [your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).

## Task State Changes

### Proxy Admin Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000017` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000018` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `23` <br/>
   **Decoded New Value**: `24` <br/>
   **Meaning**: Increments the nonce <br/>

1. **Key**: `0x9aca296d64aeaeea50429f39c01f6a25e3cb2bab02cb90aa18a20e47b97e2ed2` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x646132a1667ca7ad00d36616afba1a28116c770a][0x896f60a7707d589d89416c9f44b99b54bdfcfd52b9f505f241b5dc0e110d9b7b] to 1 (approved by the Base Multisig).

### Base Multisig - Sepolia (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `6` <br/>
   **Decoded New Value**: `7` <br/>
   **Meaning**: Increments the nonce <br/>

3. **Key**: `0x71dfe6a8ef18d31663922940612f4666ec7858fa87245eb8475fda49e94738e0` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x6af0674791925f767060dd52f7fb20984e8639d8][0xf94a73a4944796410dc97e3c46ce03a893278ba124962ab63ccb7cb36023e7b1] to 1 (approved by the Base Security Council Multisig).

### Base Security Council Multisig - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

4. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `8` <br/>
   **Decoded New Value**: `9` <br/>
   **Meaning**: Increments the nonce <br/>

### System Config (`0xf272670eb55e895584501d564AfEB048bEd26194`)

5. **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
   **Before**: `0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **After**: `0x000000000000000000000000fda350e8038728b689976d4a9e8a318400a150c5` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **Decoded New Value**: `0xfdA350e8038728B689976D4A9E8A318400A150C5` <br/>
   **Meaning**: Updates the System Config implementation address <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
