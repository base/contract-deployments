# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](https://github.com/ethereum-optimism/superchain-ops/blob/main/NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` (`0x2304CB33d95999dC29f4CeF1e35065e670a70050`) that should change during the simulation is

- Base simulation: `0xcde595956d54c692d029b4d1dc86fafc883fb82f01147f60b6b964fa00f5c88b`
- OP simulation: `0xb24bf3776c1f53a87c7f1ef62f639facf7791351b085317bd6ae049622adb10c`

calculated as explained in the nested validation doc:

```sh
SAFE_HASH=0x95d9b44bbd7e9b4f55023004e327ffa339986d5f7cc24feee87b3b19e0578049 # "Nested hash:"
SAFE_ROLE=0xd94E416cf2c7167608B2515B7e4102B41efff94f # "Council" - Base
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xcde595956d54c692d029b4d1dc86fafc883fb82f01147f60b6b964fa00f5c88b

SAFE_ROLE=0x28EDB11394eb271212ED66c08f2b7893C04C5D65 # OP
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xb24bf3776c1f53a87c7f1ef62f639facf7791351b085317bd6ae049622adb10c
```

## State Changes

### `0x4200000000000000000000000000000000000018` (`ProxyAdmin`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before**: `0x0000000000000000000000002304cb33d95999dc29f4cef1e35065e670a70050` <br/>
  **After**: `0x0000000000000000000000008cc51c3008b3f03fe483b28b8db90e19cf076a6d` <br/>
  **Meaning**: Updates the `owner` of the `ProxyAdmin` contract from the current L2 Proxy Admin Owner (`0x2304CB33d95999dC29f4CeF1e35065e670a70050`) to the L1 Proxy Admin Owner alias (`0x8cc51c3008b3f03fe483b28b8db90e19cf076a6d`).
