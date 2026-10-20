# Common EVM Scripts

Reusable EVM operation scripts live here. A script belongs in this directory when it is expected to be reused across tasks, networks, or task templates. Keep one-off task glue outside this directory.

## How To Use

Reference common scripts by explicit Forge target path from `active/evm`:

```bash
PROXY_ADMIN_OWNER=<owner-safe> INCIDENT_MULTISIG=<incident-safe> SYSTEM_CONFIG=<system-config> \
  mise exec -- forge script --rpc-url "$L1_RPC_URL" script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership
```

In Makefiles, prefer the same explicit path:

```makefile
SCRIPT_NAME = script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership
```

This keeps validation JSON portable and avoids ambiguity when different files define similarly named contracts.

## Script Inventory

| Folder | Script | Purpose | Required task files |
| --- | --- | --- | --- |
| `funding/` | `Fund.s.sol` | Sends native token from a Safe to recipients listed in `funding.json`. | `funding.json` |
| `gas/` | `IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol` | Updates gas limit, EIP-1559 elasticity, and DA footprint gas scalar on `SystemConfig`. | config env values |
| `bridge/` | `PauseBridge.s.sol` | Deposits an L2 transaction through the portal to pause or unpause the L2 bridge. | config env values |
| `bridge/` | `SetThreshold.s.sol` | Deposits an L2 transaction through the portal to update bridge partner threshold. | config env values |
| `superchain/` | `PauseSuperchainConfig.s.sol` | Pauses the chain through `SuperchainConfig`. | config env values |
| `safe/` | `UpdateSigners.s.sol` | Adds and removes Safe owners while preserving threshold. | `OwnerDiff.json` |
| `ownership/` | `TransferSystemConfigOwnership.s.sol` | Multisig script that transfers `SystemConfig` ownership from the current owner to a new owner. | `PROXY_ADMIN_OWNER`, `INCIDENT_MULTISIG`, `SYSTEM_CONFIG` env values |

## Adding Scripts

Use exact Solidity pragmas based on the contracts they import; preserve a script's original exact pragma when moving it here. Load config from environment variables into immutable variables where possible. Keep scalar task-specific values in `tasks/<task-id>/config/<network>/.env`, or use the script-documented JSON input when structured data is required, rather than hardcoding values in common scripts.

Network-specific deployment address artifacts belong under `tasks/<task-id>/config/<network>/addresses.json`. Forge broadcast records remain at task scope because Foundry separates them by script and chain ID. Verifier hash rotations use the pre-reviewed [standby operation](../../../../standby/evm/tasks/update-verifier-hashes/FACILITATOR.md), not shared common scripts.

If a script needs task-specific behavior, prefer a small task-local wrapper or Makefile target that passes environment variables into a common script. Move the underlying Solidity into this directory only when the operation itself is reusable.
