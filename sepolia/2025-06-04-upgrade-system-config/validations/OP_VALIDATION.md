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
> ### OP Multisig - Sepolia: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x5fc50133f0cf8970339976ae0ea062cc31fb588de3fe517b4e6e39feb00fa337`
# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Proxy Admin Owner - Sepolia (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### OP Multisig - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

- **Key**: `0xafedef66cba8c4c1b5df9c4f772b029036f08a7a11dccb49b567715ed721b064` <br/>
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

1. **Key**: `0x83f8c0ca1383e155c4a3c7f13f33633166e6338441eaf61876128048589792fc` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `0` <br/>
   **Decoded New Value**: `1` <br/>
   **Meaning**: Sets approvedHashes[0x6AF0674791925f767060Dd52f7fB20984E8639d8][0x412d22568533ff5b64eb78c97759492f85d19dafb473c62590b07c8f9e31a14e] to 1 (approved by the OP Multisig).

### OP Multisig - Sepolia (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `8` <br/>
   **Decoded New Value**: `9` <br/>
   **Meaning**: Increments the nonce <br/>

### System Config (`0xf272670eb55e895584501d564AfEB048bEd26194`)

3. **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
   **Before**: `0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **After**: `0x000000000000000000000000a12ae047125247baa97ed67e30513a7f95102919` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x340f923e5c7cbb2171146f64169ec9d5a9ffe647` <br/>
   **Decoded New Value**: `0xa12ae047125247baa97ed67e30513a7f95102919` <br/>
   **Meaning**: Updates the System Config implementation address <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#4-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
