# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Sepolia Nested Safe B: `0x6af0674791925f767060dd52f7fb20984e8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x96288ea8d1ed0c28d42600176370a14feea0603f1b2bf703c2f0e9c051057d91`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

### Proxy Admin Owner (`0x0fe884546476dDd290eC46318785046ef68a0BA9`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Coordinator Safe (`0x646132a1667ca7ad00d36616afba1a28116c770a`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Safe B (`0x6af0674791925f767060dd52f7fb20984e8639d8`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the owner count to 1 so the transaction simulation can occur.

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
  Who:               0x0fe884546476dDd290eC46318785046ef68a0BA9
  Contract:          Proxy Admin Owner - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000015
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000016
  Decoded Kind:      uint256
  Decoded Old Value: 21
  Decoded New Value: 22

  Summary:           Nonce increment.

----- DecodedStateDiff[1] -----
  Who:               0x0fe884546476dDd290eC46318785046ef68a0BA9
  Contract:          Proxy Admin Owner - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xab950079e3717aa6d08dc27e568f5d265f0191a3c834755df7d524ff90e68e15
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      uint256
  Decoded Old Value: 0
  Decoded New Value: 1

  Summary:           Sets an approval for this transaction from the signer. Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `0x1e4a76bbefb5005f1739856d035c83fd7ee77e73d3b38babc4c5847998ce6a1e` (you should see this in your terminal after the transaction simulation) and `NESTED_SAFE` is `0x646132a1667ca7ad00d36616afba1a28116c770a` (the safe linked above).

----- DecodedStateDiff[2] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Coordinator Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000004
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000005
  Decoded Kind:      uint256
  Decoded Old Value: 4
  Decoded New Value: 5

  Summary:           Nonce increment.

----- DecodedStateDiff[3] -----
  Who:               0x646132A1667ca7aD00d36616AFBA1A28116C770A
  Contract:          Coordinator Safe - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x2c3020a2a54d72ea6bb5dc07d7fc42853cbd98a60be682e47419bb1909c4b1bd
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      uint256
  Decoded Old Value: 0
  Decoded New Value: 1

  Summary:           Sets an approval for this transaction from the signer. Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `0xab570f85b64f6cdd9c0676ea0628f2ec677f43261b11766d7ee85e6e9cac3e24` (you should see this in your terminal after the transaction simulation) and `NESTED_SAFE` is `0x6af0674791925f767060dd52f7fb20984e8639d8` (the safe linked above).

----- DecodedStateDiff[4] -----
  Who:               0x6af0674791925f767060dd52f7fb20984e8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000003
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000004
  Decoded Kind:      uint256
  Decoded Old Value: 3
  Decoded New Value: 4

  Summary:           Nonce increment.

----- DecodedStateDiff[5] -----
  Who:               0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1
  Contract:          Dispute Game Factory - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000006f67e57c143321e266bac32a0d9d22d88ce1b3e5
  Raw New Value:     0x000000000000000000000000f0102ffe22649a5421d53acc96e309660960cf44
  Decoded Kind:      address
  Decoded Old Value: 0x6F67E57C143321e266bac32A0D9D22d88cE1b3e5
  Decoded New Value: 0xF0102fFe22649A5421D53aCC96E309660960cF44

  Summary:           Updates the `PermissionedDisputeGame` implementation address. You can verify the key derivation by running `cast index uint32 1 101` in your terminal.

----- DecodedStateDiff[6] -----
  Who:               0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1
  Contract:          Dispute Game Factory - Sepolia
  Chain ID:          11155111
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x000000000000000000000000340c1364d299ed55b193d4efcecbad8c3fb104c4
  Raw New Value:     0x000000000000000000000000cfce7dd673fbbbffd16ab936b7245a2f2db31c9a
  Decoded Kind:      address
  Decoded Old Value: 0x340c1364D299ED55B193d4eFcecBAD8c3Fb104c4
  Decoded New Value: 0xCFcE7DD673fBbbFfD16Ab936B7245A2f2dB31C9a

  Summary:           Updates the `FaultDisputeGame` implementation address. You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

----- Additional Nonce Changes -----
  Details:           You should see a nonce increment for the account you're signing with.
</pre>
