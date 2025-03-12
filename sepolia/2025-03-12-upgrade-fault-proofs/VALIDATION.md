# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Sepolia State Changes

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactory`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000071ff927ee7b96f873c249093846aa292f374aef4` <br/>
  **After**: `0x000000000000000000000000cca6a4916fa6de5d671cc77760a3b10b012cca16` <br/>
  **Meaning**: Updates the `PermissionedDisputeGame` implementation address from `0x71Ff927eE7B96F873c249093846aa292F374aEf4` to `0xcca6a4916fa6de5d671cc77760a3b10b012cca16`.
  **Verify**: You can verify the key derivation by running `cast index uint32 1 101` in your terminal.
- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000605b4248500c0a144e39bbb04c05c539e388e222` <br/>
  **After**: `0x0000000000000000000000009cd8b02e84df3ef61db3b34123206568490cb279` <br/>
  **Meaning**: Updates the `FaultDisputeGame` implementation address from `0x605B4248500c0a144e39bbB04c05C539E388E222` to `0x9cd8b02e84df3ef61db3b34123206568490cb279`.
  **Verify**: You can verify the key derivation by running `cast index uint32 0 101` in your terminal.

You should also see nonce updates for the `ProxyAdminOwner` (`0x0fe884546476dDd290eC46318785046ef68a0BA9`) and the address you're signing with.
