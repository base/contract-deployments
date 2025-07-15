# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000068f600e592799c16d1b096616edbf1681fb9c0de` <br/>
  **After**: `0x00000000000000000000000071ff927ee7b96f873c249093846aa292f374aef4` <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0x68f600e592799c16D1b096616eDbf1681FB9c0De` to the newly deployed contract address (`0x71ff927ee7b96f873c249093846aa292f374aef4`).
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.
- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000b7fb44a61fde2b9db28a84366e168b14d1a1b103` <br/>
  **After**: `0x000000000000000000000000605b4248500c0a144e39bbb04c05c539e388e222` <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0xB7fB44a61fdE2b9DB28a84366e168b14D1a1b103` to the newly deployed contract address (`0x605b4248500c0a144e39bbb04c05c539e388e222`).
  **Verify**: You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

You should also see nonce updates for the `ProxyAdminOwner` (`0x0fe884546476dDd290eC46318785046ef68a0BA9`) and the address you're signing with.
