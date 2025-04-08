# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Child Safe 1: `0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6` (Base)
>
> - Domain Hash: `0x4ac8f60706331537a33c4a4cbda024cb722855e6b160a3e8b28ab487510598b1`
> - Message Hash: `0x3a25fa618752b5d5408cef7c063ff8f08f6a833e3ac131666452d099c4cb1896`
>
> ### Child Safe 2: `0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0` (Optimism Foundation)
>
> - Domain Hash: `0xb34978142f4478f3e5633915597a756daa58a1a59a3e0234f9acd5444f1ca70e`
> - Message Hash: `0x810c12369f2efe81a2a6825b3b41e8d9b4315ba44fdf286ff23d5c4637755689`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

### `0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940` (`ProxyAdminOwner` on OP Mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Nested Safe

[For CB Signers] `0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6` (`CB Nested Safe`)
[For OP Signers] `0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0` (`OP Nested Safe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the owner count to 1 so the transaction simulation can occur.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

- **Key**: `0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: This is owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1, so the key can be derived from cast index address 0xca11bde05977b3631167028862be2a173976ca11 2.

- **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Override**: `0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11` <br/>
  **Meaning**: This is owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11, so the key can be derived from cast index address 0x0000000000000000000000000000000000000001 2.

## Task State Changes

<pre>
<code>
----- DecodedStateDiff[0] -----
  Who:               0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940
  Contract:          ProxyAdminOwner - OP Mainnet
  Chain ID:          10
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000002
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000003
  Decoded Kind:      uint256
  Decoded Old Value: 2
  Decoded New Value: 3

  Summary:           Increment nonce in ProxyAdminOwner

----- DecodedStateDiff[1] -----
  Who:               0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940
  Contract:          ProxyAdminOwner - OP Mainnet
  Chain ID:          10
  Raw Slot:          0xe23f453082938f6d8fda616d15a8d5919aec431dff18fc69ddf7fd4cd01bd59e
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      uint256
  Decoded Old Value: 0
  Decoded New Value: 1

  Summary:           Transaction approval
  Detail:            Approves the ownership transfer initiation transaction on behalf of the signing safe. The slot derivation depends on which safe is being signed for. This can be derived with `cast index bytes32 0xd806ab578902502aa5b3caf2d4a5d03b14a9e9522c8b9214ba4e05af1c39e2f4 $(cast index address $SIGNER_SAFE 8)`. For OP signers, the slot should be `0x8f6ea3dc592330bb5d3d2f07897e65e16fda3259be1ad4bc00d0033f29399eee`.
----- DecodedStateDiff[2] -----
  Who:               0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6 or 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0
  Contract:          Signer Safe - OP Mainnet
  Chain ID:          10
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      uint256
  Decoded Old Value: 0
  Decoded New Value: 1

  Summary:           Increment nonce in Signer safe

----- DecodedStateDiff[3] -----
  Who:               0xb3C2f9fC2727078EC3A2255410e83BA5B62c5B5f
  Contract:          SmartEscrow - OP Mainnet
  Chain ID:          10
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000697800000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000069780000067fba22c8cc51c3008b3f03fe483b28b8db90e19cf076a6d
  Decoded Kind:      uint48, uint48, address
  Decoded Old Value: 432000, 0, 0x0000000000000000000000000000000000000000
  Decoded New Value: 432000, 1744544300, 0x8cC51c3008b3f03Fe483B28B8Db90e19cF076a6d

  Summary:           Sets the pending default admin for SmartEscrow
  Detail:            This is a packed storage slot containing three values: `_currentDelay`, `_pendingDefaultAdminSchedule` and `_pendingDefaultAdmin`. The `_currentDelay` is set to 432000 which is 5 days (in seconds). `_pendingDefaultAdminSchedule` gets set to `block.timestamp + _currentDelay`. NOTE: the `_pendingDefaultAdminSchedule` may be different from what you see in you Tenderly simulation - this is ok! It's derived based on the current block.timestamp. The `_pendingDefaultAdmin` address gets set to `0x8cC51c3008b3f03Fe483B28B8Db90e19cF076a6d` which is the aliased address of `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (`ProxyAdminOwner`).

ATTENTION TASK REVIEWER: It is safe to continue if `_pendingDefaultAdminSchedule` is different than what is seen in the Tenderly state diff.

----- Additional Balance Changes -----
  Who:               0x420000000000000000000000000000000000001A
  Contract:          L1FeeValue - OP Mainnet
  Chain ID:          10
  Old Balance:       1892652089755161
  New Balance:       1892663085405498

  Summary:           L1 fees collected from the transaction
  Detail:            Note: these values may differ from what you see in the Tenderly simulation - that is ok!

----- Additional Nonce Changes -----
  Who:               0x6CD3850756b7894774Ab715D136F9dD02837De50

  Details:           Nonce Updates for all addresses listed above.
  Summary:
    - 0x6CD3850756b7894774Ab715D136F9dD02837De50 is the caller
</pre>
