# Common EVM Scripts

Reusable EVM operation scripts live here. A script belongs in this directory when it is expected to be reused across tasks, networks, or task templates. Keep one-off task glue outside this directory.

## How To Use

Reference common scripts by explicit Forge target path from `active/evm`:

```bash
mise exec -- forge script --rpc-url "$L1_RPC_URL" script/common/verifier-update/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
```

In Makefiles, prefer the same explicit path:

```makefile
SCRIPT_NAME = script/common/verifier-update/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
```

This keeps validation JSON portable and avoids ambiguity when different files define similarly named contracts.

## Script Inventory

| Folder | Script | Purpose | Required task files |
| --- | --- | --- | --- |
| `verifier-update/` | `DeployAggregateVerifier.s.sol` | Deploys a replacement `AggregateVerifier` by copying immutable constructor inputs from the live implementation and replacing verifier hashes. | `tasks/<task-id>/config/<network>/.env`, `tasks/<task-id>/config/<network>/network.env`, `ADDRESSES_JSON` output path |
| `verifier-update/` | `UpdateVerifierHashes.s.sol` | Multisig script that updates `DisputeGameFactory.gameImpls(gameType)` to a deployed `AggregateVerifier`. | `ADDRESSES_JSON` pointing at a JSON file with `aggregateVerifier` |
| `funding/` | `Fund.s.sol` | Sends native token from a Safe to recipients listed in `funding.json`. | `funding.json` |
| `gas/` | `IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol` | Updates gas limit, EIP-1559 elasticity, and DA footprint gas scalar on `SystemConfig`. | config env values |
| `bridge/` | `PauseBridge.s.sol` | Deposits an L2 transaction through the portal to pause or unpause the L2 bridge. | config env values |
| `bridge/` | `SetThreshold.s.sol` | Deposits an L2 transaction through the portal to update bridge partner threshold. | config env values |
| `superchain/` | `PauseSuperchainConfig.s.sol` | Pauses the chain through `SuperchainConfig`. | config env values |
| `safe/` | `UpdateSigners.s.sol` | Adds and removes Safe owners while preserving threshold. | `OwnerDiff.json` |

## Adding Scripts

Use exact Solidity pragmas based on the contracts the script imports; preserve a script's original exact pragma when moving it here. Load config from environment variables into immutable variables where possible. Keep task-specific values in `tasks/<task-id>/config/<network>/.env`, `tasks/<task-id>/config/<network>/network.env`, or task-local JSON files rather than hardcoding them in common scripts.

If a script needs task-specific behavior, prefer a small task-local wrapper or Makefile target that passes environment variables into a common script. Move the underlying Solidity into this directory only when the operation itself is reusable.
