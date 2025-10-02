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
> - Message Hash: `0x16606b54a30b976c8fe52d12ad3313580c2a8c1f8ad356e798b992c8c0100316`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the terminal commands provided.

## State Overrides

### Incident Safe - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0xf9fe516b35962c32e1a7f8f1af935904480e1fd58eb91134e29da0325fb045b4` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from msg.sender in order for the task simulation to succeed.

## Task State Changes

### Incident Safe - Mainnet (`0x14536667Cd30e52C0b458BaACcB9faDA7046E056`)

0. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000000e` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000000c` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `14` <br/>
   **Decoded New Value**: `12` <br/>
   **Meaning**: Updates the owner count <br/>

1. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `1` <br/>
   **Decoded New Value**: `3` <br/>
   **Meaning**: Updates the execution threshold <br/>

2. **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
   **Before**: `0x000000000000000000000000000000000000000000000000000000000000005a` <br/>
   **After**: `0x000000000000000000000000000000000000000000000000000000000000005b` <br/>
   **Value Type**: uint256 <br/>
   **Decoded Old Value**: `90` <br/>
   **Decoded New Value**: `91` <br/>
   **Meaning**: Increments the nonce <br/>

3. **Key**: `0x03fe74f236e7c719072f101a65bf28fcc331b8991895a586493c4ec54f013c79` <br/>
   **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **After**: `0x000000000000000000000000541a833e4303eb56a45be7e8e4a908db97568d1e` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Decoded New Value**: `0x541a833e4303eb56a45be7e8e4a908db97568d1e` <br/>
   **Meaning**: Adds `0x5b154b8587168cb984ff610f5de74289d8f68874` to the owners mapping. This key can be derived from `cast index address 0x5b154b8587168cb984ff610f5de74289d8f68874 2`. <br/>

4. **Key**: `0x51d0c1d26cdd742324bf18c3cb0c420aba6f951a054a73620fd9d0ed20dae7e8` <br/>
   **Before**: `0x00000000000000000000000073565876170a336fa02fde34eed03e3121f70ba6` <br/>
   **After**: `0x000000000000000000000000a3d3c103442f162856163d564b983ae538c6202d` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x73565876170a336fa02fde34eed03e3121f70ba6` <br/>
   **Decoded New Value**: `0xa3d3c103442f162856163d564b983ae538c6202d` <br/>
   **Meaning**: Removes `0x73565876170a336fa02fde34eed03e3121f70ba6` from the owners list. This key can be derived from `cast index address 0x26c72586fb396325f58718152fefa94e93cf177b 2`. <br/>

5. **Key**: `0x680f53193021c7b5ff32fc6154805dcdc0fe6dae60134f899becf9139fee0f45` <br/>
   **Before**: `0x000000000000000000000000b37b2d42cb0c10ebf96279cceca2cbfc47c6f236` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xb37b2d42cb0c10ebf96279cceca2cbfc47c6f236` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0x9bf96dcf51959915c8c343a3e50820ad069a1859` from the owners list. This key can be derived from `cast index address 0x9bf96dcf51959915c8c343a3e50820ad069a1859 2`. <br/>

6. **Key**: `0x7ea68b3c8a7f7867f7b6d6e5bd030223645fb027b0eb1dd797ca76b222c926e4` <br/>
   **Before**: `0x000000000000000000000000a3d3c103442f162856163d564b983ae538c6202d` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0xa3d3c103442f162856163d564b983ae538c6202d` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0x92b79e6c995ee8b267ec1ac2743d1c1fbfffc447` from the owners list. This key can be derived from `cast index address 0x92b79e6c995ee8b267ec1ac2743d1c1fbfffc447 2`. <br/>

7. **Key**: `0xb66edc9a114e89f02d0b7982582a48a539d388af46cfade8e93f01cba0973729` <br/>
   **Before**: `0x0000000000000000000000009bf96dcf51959915c8c343a3e50820ad069a1859` <br/>
   **After**: `0x000000000000000000000000b37b2d42cb0c10ebf96279cceca2cbfc47c6f236` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x9bf96dcf51959915c8c343a3e50820ad069a1859` <br/>
   **Decoded New Value**: `0xb37b2d42cb0c10ebf96279cceca2cbfc47c6f236` <br/>
   **Meaning**: Updates the owners list for `0xa31e1c38d5c37d8ecd0e94c80c0f7fd624d009a3` to point to the next address `0xb37b2d42cb0c10ebf96279cceca2cbfc47c6f236`
   since it's current next address was deleted. This key can be derived from `cast index address 0xa31e1c38d5c37d8ecd0e94c80c0f7fd624d009a3 2`. <br/>

8. **Key**: `0xd5d27d91bd7fb221a305aba9b1452dc14191edebe72a0d2caa92579343b1367f` <br/>
   **Before**: `0x00000000000000000000000092b79e6c995ee8b267ec1ac2743d1c1fbfffc447` <br/>
   **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x92b79e6c995ee8b267ec1ac2743d1c1fbfffc447` <br/>
   **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
   **Meaning**: Removes `0x73565876170a336fa02fde34eed03e3121f70ba6` from the owners list. This key can be derived from `cast index address 0x73565876170a336fa02fde34eed03e3121f70ba6 2`. <br/>

9. **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
   **Before**: `0x000000000000000000000000541a833e4303eb56a45be7e8e4a908db97568d1e` <br/>
   **After**: `0x0000000000000000000000005b154b8587168cb984ff610f5de74289d8f68874` <br/>
   **Value Type**: address <br/>
   **Decoded Old Value**: `0x541a833e4303eb56a45be7e8e4a908db97568d1e` <br/>
   **Decoded New Value**: `0x5b154b8587168cb984ff610f5de74289d8f68874` <br/>
   **Meaning**: Sets the head of the owners linked list. This key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`. <br/>

### Your Signer Address

- Nonce increment

You can now navigate back to the [README](../README.md#43-extract-the-domain-hash-and-the-message-hash-to-approve) to continue the signing process.
