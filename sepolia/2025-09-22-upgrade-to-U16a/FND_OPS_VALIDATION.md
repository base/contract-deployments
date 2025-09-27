# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Operations (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0x2b7f17c0100e6766aaac289acba0122860a51bdd64810626948b0f986f88efa5`
>

# Task State Changes

### `0x2453c1216e49704d84ea98a4dacd95738f2fc8ec` (DelayedWETH) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/configs/mainnet/base.toml#L49)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1238)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.
  
  ---
  
### `0x3154cf16ccdb4c6d922629664174b904d80f2c35` (L1StandardBridge) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_2_30` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072`
  - **Summary:** Set slot 52.
  - **Detail:** Storage slot 52 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/mainnet/base.toml#L49)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **After:** [`0xe32B192fb1DcA88fCB1C56B3ACb429e32238aDCb`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L21)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### `0x43edb88c4b80fdd2adff2412a7bebf9df42cb40e` (DisputeGameFactory) - Chain ID: 8453
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L17)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x0000000000000000000000007344da3a618b86cda67f8260c0cc2027d99f5b49`
  - **After:** `0x000000000000000000000000e3803582fd5bcdc62720d2b80f35e8ddea94e2ec`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)
  - **Detail:**  This is `gameImpls[1]` -> `0xe3803582fd5BCdc62720D2b80f35e8dDeA94e2ec`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x000000000000000000000000ab91fb6cef84199145133f75cbd96b8a31f184ed`
  - **After:** `0x000000000000000000000000e4066890367bf8a51d58377431808083a01b1e0c`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:**  This is `gameImpls[0]` -> `0xe4066890367BF8A51d58377431808083A01b1E0c`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```
  
  ---
  
### `0x49048044d57e1c92a77f79988d21fa8faf74e97e` (OptimismPortal2) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized` and `_initializing` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000909f6cf47ed12f010a796527f562bfc26c7f4e72`
  - **Summary:** Slot 62 set to `anchorStateRegistry`.
  - **Detail:** See AnchorStateRegistry below. 
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0x381E729FF983FA4BCEd820e7b922d79bF653B999`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L12)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### `0x608d94945a64503e642e6370ec598e519a2c1e53` (L1ERC721Bridge) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_2_30` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072`
  - **Summary:** systemConfig address set to OP SystemConfig proxy
  - **Detail:** Storage slot 51 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/mainnet/base.toml#L49)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x7f1d12fB2911EB095278085f721e644C1f675696`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### `0x64ae5250958cdeb83f6b61f913b5ac6ebe8efd4d` (DelayedWETH) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/configs/mainnet/base.toml#L49)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1238)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.
  
  ---
  
### `0x73a79fab69143498ed3712e519a88a918e1f4072` (SystemConfig) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized` and `_initializing` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000002105`
  - **Summary:** Slot 107 set.
  - **Detail:** L2 ChainID is set to `8453`. i.e. `cast --to-dec 0x2105`.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`
  - **Summary:** Slot 108 set.
  - **Detail:** `superchainConfig` set to [`0x95703e0982140D16f8ebA6d158FccEde42f04a4C`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1240).
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x78FFE9209dFF6Fe1c9B6F3EFdF996BeE60346D0e`
  - **After:** [`0x2bFE4A5Bd5A41e9d848d843ebCDFa15954e9A557`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L8)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address
  - **Detail:** DisputeGameFactory proxy address cleared (legacy slot deprecated)
  
  ---
  
### `0x7bb41c3008b3f03fe483b28b8db90e19cf07595c` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `10`
  - **After:** `11`
  - **Summary:** nonce
  - **Detail:** Proxy admin owner nonce incremented.

- **Key:**          `0x957c527a96bf9b903ff08c7171839fc086ceeb7151487cebfacb3beeca8882b8`
  - **Decoded Kind:** `uint256`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    To verify the slot yourself, run:
    - `res=$(cast index address 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A 8)` - Foundation Operation Safe
    - `cast index bytes32 0xe0827c2ee69fdaffc792a56c7cd5fbd1f01890591e6e3513c4de8f8f46b761fb $res`
    - Please note: the `0xe0827c2ee69fdaffc792a56c7cd5fbd1f01890591e6e3513c4de8f8f46b761fb` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.
  
  ---
  
### `0x866e82a600a1414e583f7f13623f1ac5d58b0afa` (L1CrossDomainMessenger) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000030000000000000000000000000000000000000000`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_0_20` share this slot. `initialized` (offset 20) set to 3 from 1. All other values are 0.
  
- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/configs/mainnet/base.toml#L49)
  
  ---
  
### `0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2` (AddressManager) - Chain ID: 8453
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **After:** `0x00000000000000000000000022d12e0faebd62d429514a65ebae32dd316c12d6`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v4.1.0-rc.2' L1CrossDomainMessenger at [0x22d12e0faebd62d429514a65ebae32dd316c12d6](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L19).
  - **Detail:** This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below. **Before** address matches the following cast call to `AddressManager.getAddres()`:
      - `cast call 0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url mainnet`
      - returns: `0x5D5a095665886119693F0B41d8DFeE78da033e8B`
  
  ---
  
### `0x909f6cf47ed12f010a796527f562bfc26c7f4e72` (AnchorStateRegistry) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000073a79fab69143498ed3712e519a88a918e1f40720001`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `systemConfig` share this slot. `initialized` set to 1 from 0. `systemConfig` is set to [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/configs/mainnet/base.toml#L49)
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000043edb88c4b80fdd2adff2412a7bebf9df42cb40e`
  - **Summary:** DisputeGameFactory set.
  - **Detail:** The DisputeGameFactory is set at slot 1 as [`0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/configs/mainnet/base.toml#L50)
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x6668682a7f02cd2d53840658e613c236dbb17a2cc6634a9d9041c9aa97bae646`
  - **Summary:** `startingAnchorRoot` proposal struct. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash. The actual value MAY differ based on the most recently finalized L2 output.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000000000000021baeee`
  - **Summary:** `startingAnchorRoot` struct second half initialized. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000068cafe7b00000000`
  - **Summary:** Packed slot with `respectedGameType` and `retirementTimestamp` initialized. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** The non-zero values should correspond to recent timestamp values, as [set](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L106) in the AnchorStateRegistry's initialize function.
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1238)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.

  ---

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Operations GnosisSafe) 

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `109`
  - **After:** `110`
  - **Summary:** nonce
  - **Detail:** Gnosis safe nonce incremented.