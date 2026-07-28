# Validation

This document can be used to validate the state diff resulting from the execution of the AddSigners transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## State Changes

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`ProxyAdminOwner`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Before**: `0x000000000000000000000000000000000000000000000000000000000000000e` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning**: Decrease owner count from 14 to 2.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning**: Update threshold from 1 to 2. This is really decreasing from 3 to 2 but the simulation presents this way because of the state override.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000011` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000012` <br/>
  **Meaning**: Nonce increment.

- **Key**: `0x2146980ccf4a7741c01fd860f90d2fab597ba25316f4b73d17092ab48b2eb5ce` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000646132a1667ca7ad00d36616afba1a28116c770a` <br/>
  **Meaning**: Adds `0x6af0674791925f767060dd52f7fb20984e8639d8` to the owners linked list pointing to `0x646132a1667ca7ad00d36616afba1a28116c770a`
  **Verify**: Verify key with `cast index address 0x6af0674791925f767060dd52f7fb20984e8639d8 2`

- **Key**: `0xda056de0e460c75e5163abc19a3eb1ec6a9ada3e95462ea3fc0925b123fc73d9` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Adds `0x646132a1667ca7ad00d36616afba1a28116c770a` as the tail of the owners linked list.
  **Verify**: Verify key with `cast index address 0x646132a1667ca7ad00d36616afba1a28116c770a 2`

- **Key**: `0x4bf34efa2cf5d17da7425df2ee4f6191d734167ae5ba396b1eaa05b9d92099f6` <br/>
  **Before**: `0x000000000000000000000000420c8fe1ddb0593c71487445576c87c17f177179` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0xee316db0edaee45347dfc498795a01311f085225` from the owners list. Was previously pointing to `0x420c8fE1dDb0593c71487445576c87c17f177179`.
  **Verify**: Verify key with `cast index address 0xee316db0edaee45347dfc498795a01311f085225 2`

- **Key**: `0x563d4ddf297b5a92e03dce553dc56572bfee245f134f6db63397742b674f94dd` <br/>
  **Before**: `0x000000000000000000000000ee316db0edaee45347dfc498795a01311f085225` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0xb2d9a52e76841279ef0372c534c539a4f68f8c0b` from the owners list. Was previously pointing to `0xee316db0edaee45347dfc498795a01311f085225`.
  **Verify**: Verify key with `cast index address 0xb2d9a52e76841279ef0372c534c539a4f68f8c0b 2`

- **Key**: `0x58d120a0b20e1a9e1a4e5e474f65af5c48d6f00c80f80d95320860a00359ab1a` <br/>
  **Before**: `0x0000000000000000000000002fa5d8294575a8fa880a8aec008b860fb6a70e26` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0xa8c40cc18581ff25c0d2605631514cca6590c503` from the owners list. Was previously pointing to `0x2fa5d8294575a8fa880a8aec008b860fb6a70e26`.
  **Verify**: Verify key with `cast index address 0xa8c40cc18581ff25c0d2605631514cca6590c503 2`

- **Key**: `0x7a83097f5b56a04accdbc8d4b0501bec3106db0d2c2ea1a63e7cbbf0fa91372d` <br/>
  **Before**: `0x000000000000000000000000b2d9a52e76841279ef0372c534c539a4f68f8c0b` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252` from the owners list. Was previously pointing to `0xb2d9a52e76841279ef0372c534c539a4f68f8c0b`.
  **Verify**: Verify key with `cast index address 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252 2`

- **Key**: `0x7be060a34deb1d91639bcd2c9d7b1a34999e25875869cc3a83bb8d21aae3abe8` <br/>
  **Before**: `0x00000000000000000000000079dc63ba7b5d9817a0f0840cd5373292e86735e4` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x2fa5d8294575a8fa880a8aec008b860fb6a70e26` from the owners list. Was previously pointing to `0x79dc63ba7b5d9817a0f0840cd5373292e86735e4`.
  **Verify**: Verify key with `cast index address 0x2fa5d8294575a8fa880a8aec008b860fb6a70e26 2`

- **Key**: `0xa17f6b5d5c5960e10cb741113b64d7f023e3513339475444585747297bf07208` <br/>
  **Before**: `0x0000000000000000000000009b43cc2ef6fa521127ade09e20efd6abbc5bf799` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x4ffd98b5eea905ec25aa3daf180552f67873ed78` from the owners list. Was previously pointing to `0x9b43cc2ef6fa521127ade09e20efd6abbc5bf799`.
  **Verify**: Verify key with `cast index address 0x4ffd98b5eea905ec25aa3daf180552f67873ed78 2`

- **Key**: `0xa4a7a27737970be72bc7ea3d1499d5a7ca677dcfe71298e98f16342b46fd6324` <br/>
  **Before**: `0x000000000000000000000000b04e501237d9a941b130172868201dee9b965c38` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0` from the owners list. Was previously pointing to `0xb04e501237d9a941b130172868201dee9b965c38`.
  **Verify**: Verify key with `cast index address 0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0 2`

- **Key**: `0xa90dbf3509e5dacce4ce51b1e0056ed396086cef191332ab4a46abeba6c00648` <br/>
  **Before**: `0x000000000000000000000000066a2b1419ccf2e1e672a03f14cc1d1146e717a0` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x79dc63ba7b5d9817a0f0840cd5373292e86735e4` from the owners list. Was previously pointing to `0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0`.
  **Verify**: Verify key with `cast index address 0x79dc63ba7b5d9817a0f0840cd5373292e86735e4 2`

- **Key**: `0xc737cf9e0b995a0b7c95319fd1b2a1daedbcafc9b244731b97e04bbf2a8067f3` <br/>
  **Before**: `0x0000000000000000000000009986ccaf9e3de0ffef82a0f7fa3a06d5afe07252` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x7f10098bd53519c739ca8a404afe127647d94774` from the owners list. Was previously pointing to `0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252`.
  **Verify**: Verify key with `cast index address 0x7f10098bd53519c739ca8a404afe127647d94774 2`

- **Key**: `0xcd8fdd39f0d4ab3740418f660069bb6ed71bb4dd40a37a6eb4fee616a1dc1b08` <br/>
  **Before**: `0x0000000000000000000000004ffd98b5eea905ec25aa3daf180552f67873ed78` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0xb04e501237d9a941b130172868201dee9b965c38` from the owners list. Was previously pointing to `0x4ffd98b5eea905ec25aa3daf180552f67873ed78`.
  **Verify**: Verify key with `cast index address 0xb04e501237d9a941b130172868201dee9b965c38 2`

- **Key**: `0xd5a3955556fe832b0d9dee1f7edb84880eee53ea4dc4e838bfa6bebc90480c2a` <br/>
  **Before**: `0x000000000000000000000000644d0f5c2c55a4679b4bfe057b87ba203af9ac0d` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x9b43cc2ef6fa521127ade09e20efd6abbc5bf799` from the owners list. Was previously pointing to `0x644d0f5c2c55a4679b4bfe057b87ba203af9ac0d`.
  **Verify**: Verify key with `cast index address 0x9b43cc2ef6fa521127ade09e20efd6abbc5bf799 2`

- **Key**: `0xdbe1c9b8b04b880813d25a9c5e89056031fb59c22374b4ee4da23606ff9ee5f5` <br/>
  **Before**: `0x000000000000000000000000aa2489debf1ef02ab83ba6cde4419e662de9254e` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x644d0f5c2c55a4679b4bfe057b87ba203af9ac0d` from the owners list. Was previously pointing to `0xaa2489debf1ef02ab83ba6cde4419e662de9254e`.
  **Verify**: Verify key with `cast index address 0x644d0f5c2c55a4679b4bfe057b87ba203af9ac0d 2`

- **Key**: `0xdd723b4c2a66aea3d2ac26f837bd1e7dea4ce6cca7e4fa76af2185076784453f` <br/>
  **Before**: `0x000000000000000000000000a8c40cc18581ff25c0d2605631514cca6590c503` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0x420c8fe1ddb0593c71487445576c87c17f177179` from the owners list. Was previously pointing to `0xa8c40cc18581ff25c0d2605631514cca6590c503`.
  **Verify**: Verify key with `cast index address 0x420c8fe1ddb0593c71487445576c87c17f177179 2`

- **Key**: `0xe475b9e5509f43031ff937d793c47553513dacb8de5b10e556e7da05bd6d6e54` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning**: Removes `0xaa2489debf1ef02ab83ba6cde4419e662de9254e` from the owners list. Was previously pointing to `0x0000000000000000000000000000000000000001` which marks the tail of the list.
  **Verify**: Verify key with `cast index address 0xaa2489debf1ef02ab83ba6cde4419e662de9254e 2`

- **Key**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Before**: `0x0000000000000000000000007f10098bd53519c739ca8a404afe127647d94774` <br/>
  **After**: `0x0000000000000000000000006af0674791925f767060dd52f7fb20984e8639d8` <br/>
  **Meaning**: Updates head of owners linked list from `0x7f10098BD53519c739cA8A404afE127647D94774` to `0x6af0674791925f767060dd52f7fb20984e8639d8`
  **Verify**: Verify key with `cast index address 0x0000000000000000000000000000000000000001 2`

You should also see nonce updates for the address you're signing with.
