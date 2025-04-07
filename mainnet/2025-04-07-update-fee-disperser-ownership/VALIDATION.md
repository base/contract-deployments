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
> ### Signing Safe: `0xd94E416cf2c7167608B2515B7e4102B41efff94f`
>
> - Domain Hash: `0xd16e718462d25bb73b8c6aba4611b4bc91c8e12dbf5180f9cd42af8080cffae9`
> - Message Hash: `0x276fff106b2a73daf481154f5bc0ecb1df698e1effd4e70466a1c29a4c47e04b`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

### `0xd94E416cf2c7167608B2515B7e4102B41efff94f` (`SigningSafe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Override**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Override the threshold to 1 so the transaction simulation can occur.

### Task State Changes

<pre>
<code>
----- DecodedStateDiff[0] -----
  Who:               <a href="https://basescan.org/address/0x09C7bAD99688a55a2e83644BFAed09e62bDcCcBA">0x09C7bAD99688a55a2e83644BFAed09e62bDcCcBA</a>
  Contract:          FeeDispurser - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x000000000000000000000000d94e416cf2c7167608b2515b7e4102b41efff94f
  Raw New Value:     0x000000000000000000000000a966054731540a48b28990b63dcf4f33d8ae57b2
  Decoded Kind:      address
  Decoded Old Value: <a href="https://basescan.org/address/0xd94e416cf2c7167608b2515b7e4102b41efff94f">0xd94E416cf2c7167608B2515B7e4102B41efff94f</a>
  Decoded New Value: <a href="https://basescan.org/address/0xa966054731540a48b28990b63dcf4f33d8ae57b2">0xa966054731540a48b28990b63Dcf4f33d8aE57B2</a>

  Summary:           ERC-1967 admin slot
  Detail:            Standard slot for storing the admin address in a proxy contract that follows the ERC-1967 standard.
                     This updates the FeeDispurser admin from a multisig on Base Mainnet to the aliased address of our L1 upgrade multisig.

----- DecodedStateDiff[1] -----
  Who:               <a href="https://basescan.org/address/0xd94E416cf2c7167608B2515B7e4102B41efff94f">0xd94E416cf2c7167608B2515B7e4102B41efff94f</a>
  Contract:          SignerSafe - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000009
  Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000000a
  Decoded Kind:      uint256
  Decoded Old Value: 9
  Decoded New Value: 10

  Summary:           Nonce increment
  Detail:            Increments the nonce of the Base Mainnet signer safe.

----- Additional Balance Changes -----
  Who:               0x420000000000000000000000000000000000001A
  Contract:          L1FeeValue - Base Mainnet
  Chain ID:          8453
  Old Balance:       13393636391505013773
  New Balance:       13393636396528966761

  Summary:           L1 fees collected from the transaction
  Detail:            Note: these values may differ from what you see in the Tenderly simulation - that is ok!

----- Additional Nonce Changes -----
  Who:               0x6CD3850756b7894774Ab715D136F9dD02837De50

  Details:           Nonce Updates for all addresses listed above.
  Summary:
    - 0x6CD3850756b7894774Ab715D136F9dD02837De50 is the caller
</pre>
