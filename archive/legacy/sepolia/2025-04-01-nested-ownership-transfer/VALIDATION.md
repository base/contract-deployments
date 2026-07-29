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
> ### Sepolia Safe A: `0x646132a1667ca7ad00d36616afba1a28116c770a`
>
> - Domain Hash: `0x1d3f2566fd7b1bf017258b03d4d4d435d326d9cb051d5b7993d7c65e7ec78d0e`
> - Message Hash: `0xbd6dbdbc796e78642497d9f5a0d57bbc4a82ecda60dc03ecf9e0211b29c262ba`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

### Nested Safe

`0x646132a1667ca7ad00d36616afba1a28116c770a` (`Safe A`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

## Task State Changes

<pre>
<code>
----- DecodedStateDiff[0] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000003
  Raw Old Value:     0x000000000000000000000000000000000000000000000000000000000000000e
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000002
  Decoded Kind:      uint256
  Decoded Old Value: 14
  Decoded New Value: 2

  Summary:           Update owner count to 2. This turns Safe A into a 2-of-2.

----- DecodedStateDiff[1] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000002
  Decoded Kind:      uint256
  Decoded Old Value: 1
  Decoded New Value: 2

  Summary:           Update threshold to 2. This turns Safe A into a 2-of-2.

----- DecodedStateDiff[2] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000003
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000004
  Decoded Kind:      uint256
  Decoded Old Value: 3
  Decoded New Value: 4

  Summary:           Nonce increment.

----- DecodedStateDiff[3] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x2146980ccf4a7741c01fd860f90d2fab597ba25316f4b73d17092ab48b2eb5ce
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000005dfeb066334b67355a15dc9b67317fd2a2e1f77f
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f

  Summary:           Adds 0x6af0674791925f767060dd52f7fb20984e8639d8 to owners linked list. 
                     Confirm slot key with `cast index address 0x6af0674791925f767060dd52f7fb20984e8639d8 2`.

----- DecodedStateDiff[4] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x4bf34efa2cf5d17da7425df2ee4f6191d734167ae5ba396b1eaa05b9d92099f6
  Raw Old Value:     0x000000000000000000000000420c8fe1ddb0593c71487445576c87c17f177179
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x420c8fE1dDb0593c71487445576c87c17f177179
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xee316db0edaee45347dfc498795a01311f085225 from owners linked list. 
                     Confirm slot key with `cast index address 0xee316db0edaee45347dfc498795a01311f085225 2`.

----- DecodedStateDiff[5] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x563d4ddf297b5a92e03dce553dc56572bfee245f134f6db63397742b674f94dd
  Raw Old Value:     0x000000000000000000000000ee316db0edaee45347dfc498795a01311f085225
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xEE316Db0eDaee45347DfC498795a01311F085225
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xb2d9a52e76841279ef0372c534c539a4f68f8c0b from owners linked list. 
                     Confirm slot key with `cast index address 0xb2d9a52e76841279ef0372c534c539a4f68f8c0b 2`.

----- DecodedStateDiff[6] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x58d120a0b20e1a9e1a4e5e474f65af5c48d6f00c80f80d95320860a00359ab1a
  Raw Old Value:     0x0000000000000000000000002fa5d8294575a8fa880a8aec008b860fb6a70e26
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x2Fa5D8294575A8fA880A8aec008b860Fb6A70e26
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xa8c40cc18581ff25c0d2605631514cca6590c503 from owners linked list. 
                     Confirm slot key with `cast index address 0xa8c40cc18581ff25c0d2605631514cca6590c503 2`.

----- DecodedStateDiff[7] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x7a83097f5b56a04accdbc8d4b0501bec3106db0d2c2ea1a63e7cbbf0fa91372d
  Raw Old Value:     0x000000000000000000000000b2d9a52e76841279ef0372c534c539a4f68f8c0b
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252 from owners linked list. 
                     Confirm slot key with `cast index address 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252 2`.

----- DecodedStateDiff[8] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x7be060a34deb1d91639bcd2c9d7b1a34999e25875869cc3a83bb8d21aae3abe8
  Raw Old Value:     0x00000000000000000000000079dc63ba7b5d9817a0f0840cd5373292e86735e4
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x79dc63ba7b5D9817A0f0840Cd5373292E86735E4
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x2fa5d8294575a8fa880a8aec008b860fb6a70e26 from owners linked list. 
                     Confirm slot key with `cast index address 0x2fa5d8294575a8fa880a8aec008b860fb6a70e26 2`.

----- DecodedStateDiff[9] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x917c3b0ca176e18dc93b76b7fcfca717fb0dcb74c9b02c1a4ef75f3b382fd6c9
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x0000000000000000000000000000000000000001

  Summary:           Sets 0x5dfeb066334b67355a15dc9b67317fd2a2e1f77f as tail of owners linked list.
                     Confirm slot key with `cast index address 0x5dfeb066334b67355a15dc9b67317fd2a2e1f77f 2`.

----- DecodedStateDiff[10] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xa17f6b5d5c5960e10cb741113b64d7f023e3513339475444585747297bf07208
  Raw Old Value:     0x0000000000000000000000009b43cc2ef6fa521127ade09e20efd6abbc5bf799
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x9B43cC2EF6fa521127Ade09e20efD6ABBC5BF799
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x4ffd98b5eea905ec25aa3daf180552f67873ed78 from owners linked list. 
                     Confirm slot key with `cast index address 0x4ffd98b5eea905ec25aa3daf180552f67873ed78 2`.

----- DecodedStateDiff[11] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xa4a7a27737970be72bc7ea3d1499d5a7ca677dcfe71298e98f16342b46fd6324
  Raw Old Value:     0x000000000000000000000000b04e501237d9a941b130172868201dee9b965c38
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xb04e501237d9a941b130172868201dEE9b965C38
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0 from owners linked list. 
                     Confirm slot key with `cast index address 0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0 2`.

----- DecodedStateDiff[12] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xa90dbf3509e5dacce4ce51b1e0056ed396086cef191332ab4a46abeba6c00648
  Raw Old Value:     0x000000000000000000000000066a2b1419ccf2e1e672a03f14cc1d1146e717a0
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x066a2b1419CCf2e1e672A03F14cC1d1146E717a0
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x79dc63ba7b5d9817a0f0840cd5373292e86735e4 from owners linked list. 
                     Confirm slot key with `cast index address 0x79dc63ba7b5d9817a0f0840cd5373292e86735e4 2`.

----- DecodedStateDiff[13] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xc737cf9e0b995a0b7c95319fd1b2a1daedbcafc9b244731b97e04bbf2a8067f3
  Raw Old Value:     0x0000000000000000000000009986ccaf9e3de0ffef82a0f7fa3a06d5afe07252
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x9986ccaf9E3DE0fFEF82a0f7fA3a06D5aFe07252
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x7f10098bd53519c739ca8a404afe127647d94774 from owners linked list. 
                     Confirm slot key with `cast index address 0x7f10098bd53519c739ca8a404afe127647d94774 2`.

----- DecodedStateDiff[14] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xcd8fdd39f0d4ab3740418f660069bb6ed71bb4dd40a37a6eb4fee616a1dc1b08
  Raw Old Value:     0x0000000000000000000000004ffd98b5eea905ec25aa3daf180552f67873ed78
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x4ffd98B5EEA905eC25aA3daF180552F67873Ed78
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xb04e501237d9a941b130172868201dee9b965c38 from owners linked list. 
                     Confirm slot key with `cast index address 0xb04e501237d9a941b130172868201dee9b965c38 2`.

----- DecodedStateDiff[15] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xd5a3955556fe832b0d9dee1f7edb84880eee53ea4dc4e838bfa6bebc90480c2a
  Raw Old Value:     0x000000000000000000000000644d0f5c2c55a4679b4bfe057b87ba203af9ac0d
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x644d0F5c2C55A4679b4BFe057B87ba203AF9aC0D
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x9b43cc2ef6fa521127ade09e20efd6abbc5bf799 from owners linked list. 
                     Confirm slot key with `cast index address 0x9b43cc2ef6fa521127ade09e20efd6abbc5bf799 2`.

----- DecodedStateDiff[16] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xdbe1c9b8b04b880813d25a9c5e89056031fb59c22374b4ee4da23606ff9ee5f5
  Raw Old Value:     0x000000000000000000000000aa2489debf1ef02ab83ba6cde4419e662de9254e
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xaa2489DEbF1EF02ab83bA6Cde4419E662De9254E
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x644d0f5c2c55a4679b4bfe057b87ba203af9ac0d from owners linked list. 
                     Confirm slot key with `cast index address 0x644d0f5c2c55a4679b4bfe057b87ba203af9ac0d 2`.

----- DecodedStateDiff[17] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xdd723b4c2a66aea3d2ac26f837bd1e7dea4ce6cca7e4fa76af2185076784453f
  Raw Old Value:     0x000000000000000000000000a8c40cc18581ff25c0d2605631514cca6590c503
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xa8c40CC18581Ff25c0D2605631514CCa6590c503
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x420c8fe1ddb0593c71487445576c87c17f177179 from owners linked list. 
                     Confirm slot key with `cast index address 0x420c8fe1ddb0593c71487445576c87c17f177179 2`.

----- DecodedStateDiff[18] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xe475b9e5509f43031ff937d793c47553513dacb8de5b10e556e7da05bd6d6e54
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000001
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xaa2489debf1ef02ab83ba6cde4419e662de9254e from owners linked list. 
                     Confirm slot key with `cast index address 0xaa2489debf1ef02ab83ba6cde4419e662de9254e 2`.

----- DecodedStateDiff[19] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Signer Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0
  Raw Old Value:     0x0000000000000000000000007f10098bd53519c739ca8a404afe127647d94774
  Raw New Value:     0x0000000000000000000000006af0674791925f767060dd52f7fb20984e8639d8
  Decoded Kind:      address
  Decoded Old Value: 0x7f10098BD53519c739cA8A404afE127647D94774
  Decoded New Value: 0x6AF0674791925f767060Dd52f7fB20984E8639d8

  Summary:           Sets 0x6AF0674791925f767060Dd52f7fB20984E8639d8 as head of owners linked list. 
                     Confirm slot key with `cast index address 0x0000000000000000000000000000000000000001 2`.

----- Additional Nonce Changes -----
  Details:           You should see a nonce increment for the account you're signing with.
</pre>
