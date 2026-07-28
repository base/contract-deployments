# Safe B Validation

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
> ### Safe B: `0x6af0674791925f767060dd52f7fb20984e8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x911f00103be60626fca703e1141a3d9a03f21536d178c3c827c32e7980425d4f`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Task State Changes

<pre>
<code>
----- DecodedStateDiff[0] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000005
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000006
  Decoded Kind:      uint256
  Decoded Old Value: 5
  Decoded New Value: 6

  Summary:           Increment nonce in Safe B.

----- DecodedStateDiff[1] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x50acbb719f16147a2c8ee75d12507825fd23cf8249e700977d21095d26e2750b
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000931e24b032511d8dd029aedeb44837fac251f3d8
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x931E24B032511d8dD029AedeB44837FAc251f3d8

  Summary:           Adds 0x0cf2f86c3338993ce10f74d6f4b095712c7efe26 to owners linked list
  Detail:            This storage key is derived from `cast index address 0x0cf2f86c3338993ce10f74d6f4b095712c7efe26 2`.

----- DecodedStateDiff[2] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x58d120a0b20e1a9e1a4e5e474f65af5c48d6f00c80f80d95320860a00359ab1a
  Raw Old Value:     0x0000000000000000000000002fa5d8294575a8fa880a8aec008b860fb6a70e26
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x2Fa5D8294575A8fA880A8aec008b860Fb6A70e26
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xa8c40cc18581ff25c0d2605631514cca6590c503 from owners linked list
  Detail:            This storage key is derived from `cast index address 0xa8c40cc18581ff25c0d2605631514cca6590c503 2`.

----- DecodedStateDiff[3] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x789d0a937d11245f00c7805a1652391bdbf3de0209dd993a5d6bc0ea4964bd5e
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000007f10098bd53519c739ca8a404afe127647d94774
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x7f10098BD53519c739cA8A404afE127647D94774

  Summary:           Adds 0xedecf2c444559210a865a22acfc6a2a25590ab1b to owners linked list
  Detail:            This storage key is derived from `cast index address 0xedecf2c444559210a865a22acfc6a2a25590ab1b 2`.

----- DecodedStateDiff[4] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x7be060a34deb1d91639bcd2c9d7b1a34999e25875869cc3a83bb8d21aae3abe8
  Raw Old Value:     0x00000000000000000000000079dc63ba7b5d9817a0f0840cd5373292e86735e4
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x79dc63ba7b5D9817A0f0840Cd5373292E86735E4
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x2fa5d8294575a8fa880a8aec008b860fb6a70e26 from owners linked list
  Detail:            This storage key is derived from `cast index address 0x2fa5d8294575a8fa880a8aec008b860fb6a70e26 2`.

----- DecodedStateDiff[5] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xa4a7a27737970be72bc7ea3d1499d5a7ca677dcfe71298e98f16342b46fd6324
  Raw Old Value:     0x000000000000000000000000b04e501237d9a941b130172868201dee9b965c38
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0xb04e501237d9a941b130172868201dEE9b965C38
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           This removes 0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0 from the owners linked list.
  Detail:            This storage key is derived from `cast index address 0x066a2b1419ccf2e1e672a03f14cc1d1146e717a0 2`

----- DecodedStateDiff[6] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xa90dbf3509e5dacce4ce51b1e0056ed396086cef191332ab4a46abeba6c00648
  Raw Old Value:     0x000000000000000000000000066a2b1419ccf2e1e672a03f14cc1d1146e717a0
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x066a2b1419CCf2e1e672A03F14cC1d1146E717a0
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0x79dc63ba7b5d9817a0f0840cd5373292e86735e4 from owners linked list
  Detail:            This storage key is derived from `cast index address 0x79dc63ba7b5d9817a0f0840cd5373292e86735e4 2`.

----- DecodedStateDiff[7] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xb06fd2848181e1497bbaa80b8d007c335c7806a2e47211a7bba7a9af63e0ca64
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000f2fb17eab635f036da7864b8e39ef8e9a03441df
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xf2Fb17eab635f036Da7864B8e39ef8e9A03441df

  Summary:           Adds 0xe45ac81ea7f53dea5f0bd6caa0733dd5c02d3b60 to owners linked list
  Detail:            This storage key is derived from `cast index address 0xe45ac81ea7f53dea5f0bd6caa0733dd5c02d3b60 2`.

----- DecodedStateDiff[8] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xb7148df08fba2104e13e2db097b95b457295019a50d577cc90c6010aba3100d1
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000e45ac81ea7f53dea5f0bd6caa0733dd5c02d3b60
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xE45AC81eA7f53dea5f0bd6Caa0733DD5c02d3b60

  Summary:           Adds 0x931e24b032511d8dd029aedeb44837fac251f3d8 to owners linked list
  Detail:            This storage key is derived from `cast index address 0x931e24b032511d8dd029aedeb44837fac251f3d8 2`.

----- DecodedStateDiff[9] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xcd8fdd39f0d4ab3740418f660069bb6ed71bb4dd40a37a6eb4fee616a1dc1b08
  Raw Old Value:     0x0000000000000000000000004ffd98b5eea905ec25aa3daf180552f67873ed78
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Decoded Kind:      address
  Decoded Old Value: 0x4ffd98B5EEA905eC25aA3daF180552F67873Ed78
  Decoded New Value: 0x0000000000000000000000000000000000000000

  Summary:           Removes 0xb04e501237d9a941b130172868201dee9b965c38 from owners linked list
  Detail:            This storage key is derived from `cast index address 0xb04e501237d9a941b130172868201dee9b965c38 2`.

----- DecodedStateDiff[10] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xdd723b4c2a66aea3d2ac26f837bd1e7dea4ce6cca7e4fa76af2185076784453f
  Raw Old Value:     0x000000000000000000000000a8c40cc18581ff25c0d2605631514cca6590c503
  Raw New Value:     0x0000000000000000000000004ffd98b5eea905ec25aa3daf180552f67873ed78
  Decoded Kind:      address
  Decoded Old Value: 0xa8c40CC18581Ff25c0D2605631514CCa6590c503
  Decoded New Value: 0x4ffd98B5EEA905eC25aA3daF180552F67873Ed78

  Summary:           Results from removing 0xa8c40CC18581Ff25c0D2605631514CCa6590c503 from owners linked list
  Detail:            This storage key is derived from `cast index address 0x420c8fe1ddb0593c71487445576c87c17f177179 2`. This updates the list pointer for 0x420c8fe1ddb0593c71487445576c87c17f177179 from 0xa8c40CC18581Ff25c0D2605631514CCa6590c503 to 0x4ffd98B5EEA905eC25aA3daF180552F67873Ed78.

----- DecodedStateDiff[11] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xdf293ebdd99010d44bfef5d86d47c7943a4e69db74a426354dc622e6d4d85761
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000edecf2c444559210a865a22acfc6a2a25590ab1b
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xEdecf2c444559210a865a22acfc6A2a25590Ab1b

  Summary:           Adds 0xf2fb17eab635f036da7864b8e39ef8e9a03441df to owners linked list
  Detail:            This storage key is derived from `cast index address 0xf2fb17eab635f036da7864b8e39ef8e9a03441df 2`.

----- DecodedStateDiff[12] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0
  Raw Old Value:     0x0000000000000000000000007f10098bd53519c739ca8a404afe127647d94774
  Raw New Value:     0x0000000000000000000000000cf2f86c3338993ce10f74d6f4b095712c7efe26
  Decoded Kind:      address
  Decoded Old Value: 0x7f10098BD53519c739cA8A404afE127647D94774
  Decoded New Value: 0x0CF2F86C3338993ce10F74d6f4B095712c7efe26

  Summary:           Updates the head of the owners linked list to 0x0CF2F86C3338993ce10F74d6f4B095712c7efe26
  Detail:            This storage key is derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

----- Additional Nonce Changes -----
  Details:           You should see a nonce increment for the account you're signing with.
</pre>
