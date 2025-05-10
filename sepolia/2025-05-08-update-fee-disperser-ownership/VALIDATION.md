# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.


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
  Who:               0x76355A67fCBCDE6F9a69409A8EAd5EaA9D8d875d
  Contract:          FeeDisperser - Base Sepolia
  Chain ID:          84532
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000004672425c27a942bb27e7b9709c1b21ab89a3ca13
  Raw New Value:     0x0000000000000000000000006f0fb066334b67355a15dc9b67317fd2a2e20890
  Decoded Kind:      address
  Decoded Old Value: 0x4672425c27a942bb27e7b9709c1b21ab89a3ca13
  Decoded New Value: 0x6F0fB066334B67355A15dc9b67317fd2A2E20890

  Summary:           Update FeeDisperser owner from `0x4672425c27a942bb27e7b9709c1b21ab89a3ca13` to `0x6F0fB066334B67355A15dc9b67317fd2A2E20890`

----- Additional Nonce Changes -----
  Who:               0x4672425c27a942bb27e7b9709c1b21ab89a3ca13

  Details:           Nonce Updates for all addresses listed above.
  Summary:
    - 0x4672425c27a942bb27e7b9709c1b21ab89a3ca13 is the caller
</pre>
