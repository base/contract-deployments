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
> ### Sepolia Safe B: `0x6af0674791925f767060dd52f7fb20984e8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x7d36496183631f74bd08724fe13d8c30ffe9600a334d642e5141ea030ee83dac`

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

### Safe B (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)

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
  Raw Slot:          0x817eda31e1518570433e4bc8b57d7ea96fcd5460045124fefb39dba853c8bcf1
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Decoded Kind:      uint256
  Decoded Old Value: 0
  Decoded New Value: 1

  Summary:           Sets an approval for this transaction from the signer. Compute the expected raw slot key with `cast index bytes32 $NESTED_HASH $(cast index address $NESTED_SAFE 8)` where `NESTED_HASH` is `0x1e4a76bbefb5005f1739856d035c83fd7ee77e73d3b38babc4c5847998ce6a1e` (you should see this in your terminal after the transaction simulation) and `NESTED_SAFE` is `0x6af0674791925f767060dd52f7fb20984e8639d8` (the safe linked above).

----- DecodedStateDiff[2] -----
  Who:               0x6AF0674791925f767060Dd52f7fB20984E8639d8
  Contract:          Safe B - Sepolia
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000003
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000004
  Decoded Kind:      uint256
  Decoded Old Value: 3
  Decoded New Value: 4

  Summary:           Nonce increment.

----- DecodedStateDiff[3] -----
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

----- DecodedStateDiff[4] -----
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
