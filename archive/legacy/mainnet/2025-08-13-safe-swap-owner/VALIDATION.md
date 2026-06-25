# Validation

This document can be used to validate the state diff resulting from the execution of the swap owner transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and no others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `<safe_address>` (Base `GnosisSafeProxy`)

- **Key**: `owners[newOwner]` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `Next address in the list returned by getOwners()` <br/>
  **Meaning**: Sets the address value at the mapping key `owners[newOwner]` to the next address in the list returned by `getOwners()`. This is the first step required to replace the `oldOwner` address in the linked list data structure of owners.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <newOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.
- **Key**: `owners[prevOwner]` <br/>
  **Before**: `oldOwner address` <br/>
  **After**: `newOwner address` <br/>
  **Meaning**: Points the address value at mapping key `owners[prevOwner]` to the `newOwner` address. This is the second step required to replace the `oldOwner` address in the linked list data structure of owners.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <prevOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.
- **Key**: `owners[oldOwner]` <br/>
  **Before**: `Next address in the list returned by getOwners()` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Clears the address value at the mapping key `owners[oldOwner]`. This removes the final reference to the `oldOwner` from the `owners` linked list.  <br/>
  **Verify**: You can verify the key derivation by running `cast index address <oldOwner> 2` in your terminal. See the following section for an explanation of the storage and value calculations.
- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `Current nonce value (in hexadecimal)` <br/>
  **After**: `Current nonce value + 1 (in hexadecimal)` <br/>
  **Meaning**: Increments the `nonce` value of the Gnosis Safe. <br/>
  **Verify**: You can verify the value by running `cast storage <safe_address> 5 -r <rpc_url>` in your terminal. This value represents the _current_ nonce value.

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
