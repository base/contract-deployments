# Validation

This document can be used to validate the state diff resulting from the execution of the swap owner transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and no others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Base Nested Multisig - Mainnet: `0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`
>
> - Domain Hash: `0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac`
> - Message Hash: `0xf1160d2510c49ad09ba91899c9584a87bf4292a5272a2751796281a91cb8b9b4`

# State Validations

## State Overrides

### Base Nested Multisig - Mainnet (`0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x941b9cdcb5979673e06ce272a4b3851457b1a7a92c5034b46f0cdf4d3ffbf36d` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Simulates an approval from `msg.sender` in order for the task simulation to succeed. Note: The Key might be different as it corresponds to the slot associated with [your signer address](https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol#L69).

## State Changes

### `0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110` (Base `GnosisSafeProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Value Type**: uint256 <br/>
  **Decoded Old Value**: `2` <br/>
  **Decoded New Value**: `3` <br/>
  **Meaning**: Increments the `nonce` value of the Gnosis Safe. <br/>
  **Verify**: You can verify the value by running `cast storage <safe_address> 5 -r <rpc_url>` in your terminal. This value represents the _current_ nonce value.

- **Key**: `0x41ed7d57be3aeb16e937147407ec4fe9778850776e44a977f984860d4294c66f` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000003dad2200849925bb46d9bf05afa5f7f213f4c18e` <br/>
  **Value Type**: address <br/>
  **Decoded Old Value**: `0x0000000000000000000000000000000000000000` <br/>
  **Decoded New Value**: `0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E` <br/>
  **Meaning**: Sets the address value at the mapping key `owners[newOwner]` to the next address in the list returned by `getOwners()`. This is the first step required to replace the `oldOwner` address in the linked list data structure of owners.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <newOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.

- **Key**: `0x46b3491a8cd829af805c1f7fb76736ca5fd88e02a78fcec356aaa2b41bf599db` <br/>
  **Before**: `0x0000000000000000000000003dad2200849925bb46d9bf05afa5f7f213f4c18e` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Value Type**: address <br/>
  **Decoded Old Value**: `0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E` <br/>
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` <br/>
  **Meaning**: Clears the address value at the mapping key `owners[oldOwner]`. This removes the final reference to the `oldOwner` from the `owners` linked list.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <oldOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.

- **Key**: `0xf50027dc233102bb13bb30a38326315505fe2452eaf2e2f78f1c0da0084d86c4` <br/>
  **Before**: `0x0000000000000000000000005fbefa105bbd53b43bf537cbc5cd30804dd0c993` <br/>
  **After**: `0x0000000000000000000000001c870776b168a9ffae80c51f050c611edd246741` <br/>
  **Value Type**: address <br/>
  **Decoded Old Value**: `0x5FbEFA105bbd53b43bf537Cbc5cD30804Dd0c993` <br/>
  **Decoded New Value**: `0x1c870776B168A9ffAE80c51f050C611eDd246741` <br/>
  **Meaning**: Points the address value at mapping key `owners[prevOwner]` to the `newOwner` address. This is the second step required to replace the `oldOwner` address in the linked list data structure of owners.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <prevOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.

### Your Signer Address

- Nonce increment

### `SwapOwner` Storage Calculations

The [`swapOwner`](https://github.com/safe-global/safe-smart-account/blob/8823fa3e44936e2aecf23bb97662eb0ffeff2f93/contracts/base/OwnerManager.sol#L94) function in the Gnosis Safe implementation will perform [three storage changes](https://github.com/safe-global/safe-smart-account/blob/8823fa3e44936e2aecf23bb97662eb0ffeff2f93/contracts/base/OwnerManager.sol#L106-L108):

- Point the `newOwner` address to the owner address that was previously pointed to by the `oldOwner` that is being removed.
- Point the `prevOwner` address to the `newOwner` address.
- Remove the pointer value stored at the mapping of the `oldOwner` address.

These changes are needed on account of the data structure that holds the owners in the Gnosis Safe implementation being a singly-linked list. To calculate the expected storage locations of these mapping values, we can perform the following:

#### Calculating `prevOwner`

The `prevOwner` is identified by the script, but can be manually checked by running the cast command:

```sh
cast call <safe_address> "getOwners()(address[])" -r <rpc_url>

[0x6CD3850756b7894774Ab715D136F9dD02837De50, 0x3cd692eCE8b6573A2220ae00d0dEb98f0DfFA9a1, 0x5FbEFA105bbd53b43bf537Cbc5cD30804Dd0c993, 0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E, 0xB011a32ED8b4F70D9943A2199F539bbeCd7b62F7, 0xf9e320f3dA12E68af219d9E2A490Dd649f6B177c]
```

The order that the owner addresses are returned in indicates who the `prevOwner` and next owner values of the address to remove is. If the owner to remove is the 0th value, its `prevOwner` would be the special sentinel node value [`SENTINEL_OWNERS`](https://github.com/safe-global/safe-smart-account/blob/f9cc387f72640eb2c1d6ae8abe9d6ff25ca1ed3b/contracts/base/OwnerManager.sol#L17). Otherwise, if the owner to remove is the last value in the array, its next owner address would be the special sentinel node value [`SENTINEL_OWNERS`](https://github.com/safe-global/safe-smart-account/blob/f9cc387f72640eb2c1d6ae8abe9d6ff25ca1ed3b/contracts/base/OwnerManager.sol#L17).

#### Calculating storage locations and values

With the order of the owners identified, we can calculate the expected storage mapping locations and their values. For the first change, the expected storage slot and value will be the following:

**Storage Slot**: `cast index address <newOwner> 2`

**Value**: The address immediately following `oldOwner` in the `getOwners` list, or the `SENTINEL_OWNERS` special value if the address is the last in the array.

For the second change, it will be:

**Storage Slot**: `cast index address <prevOwner> 2`

**Value**: `newOwner` address

For the final storage change, it will be:

**Storage Slot**: `cast index address <oldOwner> 2`

**Value**: `address(0)`

Note that for all the above storage calculations, we used storage slot 2 as that is the location of the `owners` mapping in the Gnosis Safe storage layout. This can be confirmed with the following command: `cast storage <safe_address> -r <rpc_url> -e <etherscan_api_key>`. Also note that while the storage changes may not appear in the same order in the Tenderly simulation, there should still be 3 storage changes related to the `owner` linked list and one change for the `nonce` value on the `GnosisSafeProxy`. There should be no additional changes to the proxy besides these ones!
