# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

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
  Who:               0xC5aE9023bFA79124ffA50169E1423E733D0166f1
  Contract:          ProxyAdmin - Sepolia Alpha
  Chain ID:          11155111
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x000000000000000000000000af6e0e871f38c7b653700f7cbaedafaa2784d430
  Raw New Value:     0x0000000000000000000000000fe884546476ddd290ec46318785046ef68a0ba9
  Decoded Kind:      address
  Decoded Old Value: 0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430
  Decoded New Value: 0x0fe884546476dDd290eC46318785046ef68a0BA9

  Summary:           Update ProxyAdmin owner from `0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430` to `0x0fe884546476dDd290eC46318785046ef68a0BA9`

----- Additional Nonce Changes -----
  Who:               0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430

  Details:           Nonce Updates for all addresses listed above.
  Summary:
    - 0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430 is the caller
</pre>
