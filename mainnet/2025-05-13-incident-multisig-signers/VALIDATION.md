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
> ### Incident Safe - Mainnet: `0x14536667Cd30e52C0b458BaACcB9faDA7046E056`
>
> - Domain Hash: `0xf3474c66ee08325b410c3f442c878d01ec97dd55a415a307e9d7d2ea24336289`
> - Message Hash: `0xe243a7b102ee55fab372a2a658969edbdd4bc72f64ec3bc6d1b00df3c18186c7`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Incident Safe - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xcb04adfc92ac8bcb063843650e7eccac4db23770c71f915f24843a4bac7f4c42` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from msg.sender in order for the task simulation to succeed.

## Task State Changes

### Incident Safe - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `1` <br/>
   **Decoded New Value**: `3` <br/>
   **Meaning**: Updates the execution threshold <br/>

1. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000003f` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000040` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `63` <br/>
   **Decoded New Value**: `64` <br/>
   **Meaning**: Increments the nonce <br/>

2. **Key**: `0x3e47e5a7008d8f759d6280371eab88504a2da941f80f6ebfdd83b6154e409aff` <br/>
   **Before**: `0x000000000000000000000000a7a5e47d3959bf134e3ecdeb1f62e054f0d58a18` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xa7a5e47D3959bf134e3EcdEb1f62e054f0D58a18` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0x969ffd102fbf304d4e401999333fe9397dac653d` from the owners list. This key can be derived from `cast index address 0x969ffd102fbf304d4e401999333fe9397dac653d 2`. <br/>

3. **Key**: `0x3ec917e183b9e8fcc093eeab8fb03c822155d7e91a8de91af2ddd607da113e81` <br/>
   **Before**: `0x000000000000000000000000969ffd102fbf304d4e401999333fe9397dac653d` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x969ffD102fbF304d4e401999333FE9397DaC653D` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0x8e5de5ca219e3ffc9cdeb2dc7d71b8a199cd2c4f` from the owners list. This key can be derived from `cast index address 0x8e5de5ca219e3ffc9cdeb2dc7d71b8a199cd2c4f 2`. <br/>

4. **Key**: `0x56a2719ad2beef0c19441f84d407dd2c9784ca8c8f85fb6f5c8696628c63fd10` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x0000000000000000000000004427683aa1f0ff25ccdc4a5db83010c1de9b5ff4` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Decoded New Value**: `0x4427683AA1f0ff25ccDC4a5Db83010c1DE9b5fF4` <br/>
   **Meaning**: Adds `0x541a833e4303eb56a45be7e8e4a908db97568d1e` to the owners mapping. This key can be derived from `cast index address 0x541a833e4303eb56a45be7e8e4a908db97568d1e 2`. <br/>

5. **Key**: `0x62fe150de8c52e909210d81e8e6e1cf7130e5cd644fb4b95d1cdf9c7ffa67ce1` <br/>
   **Before**: `0x0000000000000000000000005468985b560d966dedea2daf493f5756101137dc` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x5468985B560D966dEDEa2DAF493f5756101137DC` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0xe32868ec7762650dde723e945d638a05900974f4` from the owners list. This key can be derived from `cast index address 0xe32868ec7762650dde723e945d638a05900974f4 2`. <br/>

6. **Key**: `0x680f53193021c7b5ff32fc6154805dcdc0fe6dae60134f899becf9139fee0f45` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x000000000000000000000000b37b2d42cb0c10ebf96279cceca2cbfc47c6f236` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Decoded New Value**: `0xB37B2D42cb0C10ebf96279CcECa2cBFc47C6f236` <br/>
   **Meaning**: Adds `0x9bf96dcf51959915c8c343a3e50820ad069a1859` to the owners list. This key can be derived from `cast index address 0x9bf96dcf51959915c8c343a3e50820ad069a1859 2`. <br/>

7. **Key**: `0x738e743b0e4f327810ae0f138c7c5012854e2f43043547bef588cf84df24f166` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x00000000000000000000000024c3ae1aedb8142d32bb6d3b988f5910f272d53b` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Decoded New Value**: `0x24c3AE1AeDB8142D32BB6d3B988f5910F272D53b` <br/>
   **Meaning**: Adds `0xb37b2d42cb0c10ebf96279cceca2cbfc47c6f236` to the owners list. This key can be derived from `cast index address 0xb37b2d42cb0c10ebf96279cceca2cbfc47c6f236 2`. <br/>

8. **Key**: `0x7ea68b3c8a7f7867f7b6d6e5bd030223645fb027b0eb1dd797ca76b222c926e4` <br/>
   **Before**: `0x000000000000000000000000c29a4a69886d5ee1e08bdbbdd4e35558a668ee04` <br/>
   **After**: `0x000000000000000000000000a3d3c103442f162856163d564b983ae538c6202d` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xC29A4a69886d5ee1E08BDBbdd4e35558A668ee04` <br/>
   **Decoded New Value**: `0xa3D3c103442F162856163d564b983ae538c6202D` <br/>
   **Meaning**: Removes `0xC29A4a69886d5ee1E08BDBbdd4e35558A668ee04` from the owners list. This key can be derived from `cast index address 0x92b79e6c995ee8b267ec1ac2743d1c1fbfffc447 2`. <br/>

9. **Key**: `0x95d1aa1bb172c2bf1f8f9d26147578664d9c87a13833e5ec836b94816dd5e63c` <br/>
   **Before**: `0x000000000000000000000000e32868ec7762650dde723e945d638a05900974f4` <br/>
   **After**: `0x0000000000000000000000005468985b560d966dedea2daf493f5756101137dc` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xe32868ec7762650DdE723e945D638A05900974F4` <br/>
   **Decoded New Value**: `0x5468985B560D966dEDEa2DAF493f5756101137DC` <br/>
   **Meaning**: Removes `0xe32868ec7762650DdE723e945D638A05900974F4` from the owners list. This key can be derived from `cast index address 0x7ad8e6b7b1f6d66f49559f20053cef8a7b6c488e 2`. <br/>

10. **Key**: `0xaae1b570ab817af80d8c0d204fb15e028c217d77afad5a3c8113d93575274af8` <br/>
    **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
    **After**: `0x000000000000000000000000a31e1c38d5c37d8ecd0e94c80c0f7fd624d009a3` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
    **Decoded New Value**: `0xA31E1c38d5c37D8ECd0e94C80C0F7FD624d009A3` <br/>
    **Meaning**: Adds `0x4427683aa1f0ff25ccdc4a5db83010c1de9b5ff4` to the owners mapping. This key can be derived from `cast index address 0x4427683aa1f0ff25ccdc4a5db83010c1de9b5ff4 2`. <br/>

11. **Key**: `0xabc107d46e415c7424b4c72993ba52c8e074fa848b10488b90787fa482da8347` <br/>
    **Before**: `0x0000000000000000000000008e5de5ca219e3ffc9cdeb2dc7d71b8a199cd2c4f` <br/>
    **After**: `0x00000000000000000000000049243dce94e0f5a1b08b9556bbec5a84363c3839` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0x8e5de5cA219e3FFC9cdEb2Dc7D71B8a199cd2C4F` <br/>
    **Decoded New Value**: `0x49243DcE94e0f5A1B08b9556bBEc5a84363c3839` <br/>
    **Meaning**: Removes `0x8e5de5cA219e3FFC9cdEb2Dc7D71B8a199cd2C4F` from the owners list. This key can be derived from `cast index address 0xa3d3c103442f162856163d564b983ae538c6202d 2`. <br/>

12. **Key**: `0xb66edc9a114e89f02d0b7982582a48a539d388af46cfade8e93f01cba0973729` <br/>
    **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
    **After**: `0x0000000000000000000000009bf96dcf51959915c8c343a3e50820ad069a1859` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
    **Decoded New Value**: `0x9bF96DCf51959915c8c343a3E50820Ad069A1859` <br/>
    **Meaning**: Adds `0xa31e1c38d5c37d8ecd0e94c80c0f7fd624d009a3` to the owners list. This key can be derived from `cast index address 0xa31e1c38d5c37d8ecd0e94c80c0f7fd624d009a3 2`. <br/>

13. **Key**: `0xca733c6877c078939a707e6eea1eb08fff5a682cadbaa29107c5aabdc24983b8` <br/>
    **Before**: `0x000000000000000000000000a3d3c103442f162856163d564b983ae538c6202d` <br/>
    **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0xa3D3c103442F162856163d564b983ae538c6202D` <br/>
    **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
    **Meaning**: Removes `0xc29a4a69886d5ee1e08bdbbdd4e35558a668ee04` from the owners list. This key can be derived from `cast index address 0xc29a4a69886d5ee1e08bdbbdd4e35558a668ee04 2`. <br/>

14. **Key**: `0xd4e846dd026aea5c5e68c86a209545a745eebd848b6efbdf801969a785e0fdd8` <br/>
    **Before**: `0x00000000000000000000000049243dce94e0f5a1b08b9556bbec5a84363c3839` <br/>
    **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0x49243DcE94e0f5A1B08b9556bBEc5a84363c3839` <br/>
    **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
    **Meaning**: Removes `0xa7a5e47d3959bf134e3ecdeb1f62e054f0d58a18` from the owners list. This key can be derived from `cast index address 0xa7a5e47d3959bf134e3ecdeb1f62e054f0d58a18 2`. <br/>

15. **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
    **Before**: `0x00000000000000000000000024c3ae1aedb8142d32bb6d3b988f5910f272d53b` <br/>
    **After**: `0x000000000000000000000000541a833e4303eb56a45be7e8e4a908db97568d1e` <br/>
    **Value Type**: address <br/>
    **Decoded Old Value**: `0x24c3AE1AeDB8142D32BB6d3B988f5910F272D53b` <br/>
    **Decoded New Value**: `0x541a833E4303EB56a45bE7E8E4A908db97568d1e` <br/>
    **Meaning**: Sets the head of the owners linked list. This key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`. <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#43-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
