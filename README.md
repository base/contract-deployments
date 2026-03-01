![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base/contracts](https://github.com/base/contracts).

This repo is structured with each network having a high-level directory which contains subdirectories of any "tasks" (contract deployments/calls) that have happened for that network. Supported networks are `mainnet`, `sepolia`, and `sepolia-alpha`.

<!-- Badge row 1 - status -->

[![GitHub contributors](https://img.shields.io/github/contributors/base/contract-deployments)](https://github.com/base/contract-deployments/graphs/contributors)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/w/base/contract-deployments)](https://github.com/base/contract-deployments/graphs/contributors)
[![GitHub Stars](https://img.shields.io/github/stars/base/contract-deployments.svg)](https://github.com/base/contract-deployments/stargazers)
![GitHub repo size](https://img.shields.io/github/repo-size/base/contract-deployments)
[![GitHub](https://img.shields.io/github/license/base/contract-deployments?color=blue)](https://github.com/base/contract-deployments/blob/main/LICENSE)

<!-- Badge row 2 - links and profiles -->

[![Website base.org](https://img.shields.io/website-up-down-green-red/https/base.org.svg)](https://base.org)
[![Blog](https://img.shields.io/badge/blog-up-green)](https://base.mirror.xyz/)
[![Docs](https://img.shields.io/badge/docs-up-green)](https://docs.base.org/)
[![Discord](https://img.shields.io/discord/1067165013397213286?label=discord)](https://base.org/discord)
[![Twitter BuildOnBase](https://img.shields.io/twitter/follow/BuildOnBase?style=social)](https://x.com/BuildOnBase)

<!-- Badge row 3 - detailed status -->

[![GitHub pull requests by-label](https://img.shields.io/github/issues-pr-raw/base/contract-deployments)](https://github.com/base/contract-deployments/pulls)
[![GitHub Issues](https://img.shields.io/github/issues-raw/base/contract-deployments.svg)](https://github.com/base/contract-deployments/issues)

## Setup

First, install forge if you don't have it already:

- Run `make install-foundry` to install [`Foundry`](https://github.com/foundry-rs/foundry/commit/3b1129b5bc43ba22a9bcf4e4323c5a9df0023140).

To execute a new task, run one of the following commands (depending on the type of change you're making):

- For a generic task: `make setup-task network=<network> task=<task-name>`
- For gas increase tasks: `make setup-gas-increase network=<network>`
- For combined gas, elasticity, and DA footprint gas scalar tasks: `make setup-gas-and-elasticity-increase network=<network>`
- For funding: `make setup-funding network=<network>`
- For fault proof upgrade: `make setup-upgrade-fault-proofs network=<network>`
- For safe management tasks: `make setup-safe-management network=<network>`
- For funding tasks: `make setup-funding network=<network>`
- For updating the partner threshold in Base Bridge: `make setup-bridge-partner-threshold network=<network>`
- For pausing / un-pausing Base Bridge: `make setup-bridge-pause network=<network>`
- For switching to a permissioned game and retiring dispute games: `make setup-switch-to-permissioned-game network=<network>`
- For pausing SuperchainConfig: `make setup-superchain-config-pause network=<network>`

Next, `cd` into the directory that was created for you and follow the steps listed below for the relevant template.

> **👥 For Signers:** Please read the [Signer Guide](SIGNER.md) for step-by-step instructions on using the validation UI.

Please note, for some older tasks (that have not yet been adapted to use the signer tool) you will need to manually create validation file(s) for your task as they are bespoke to each task and therefore not created automatically as a part of the templates. We use one validation Markdown file per multisig involved in the task, so if there's only one multisig involved in your task, then you can simply create a `VALIDATION.md` file at the root of your task containing the validation instructions, while if there are multiple multisigs involved in the task, then create a `validations/` sub-directory at the root of your task containing the corresponding validation Markdown files. If you need examples to work from, you can browse through similar past tasks in this repo and adapt them to your specific task. Also, please note that we have tooling to generate these files (like the `task-signer-tool`) which removes the manual aspect of creating these validation files, we will soon update these instructions to reflect how this process can be automated.

## Network configuration

Each network directory (`mainnet/`, `sepolia/`, `sepolia-alpha/`) contains a `.env` file that defines all contract addresses and network metadata for that chain. These variables are automatically available to every task via the `include ../.env` directive in each task's Makefile, so there is no need to manually load addresses in individual tasks or templates.

The network `.env` files contain:
- **Network metadata** — `NETWORK`, `L1_RPC_URL`, `L2_RPC_URL`, `L1_CHAIN_ID`, `L2_CHAIN_ID`, `LEDGER_ACCOUNT`
- **Admin addresses** — multisig addresses, proposer, challenger, batch sender, etc.
- **L1 contract addresses** — proxy admin, bridges, dispute game factories, system config, etc.
- **L2 contract addresses** — fee vaults, cross-domain messenger, standard bridge, etc.

All address variables are prefixed with `export` so they are available to child shell processes (Forge scripts, shell commands, etc.). Foundry scripts can access them via `vm.envAddress("VARIABLE_NAME")`.

> **Note:** If you need to add or update a contract address, edit the corresponding `{network}/.env` file directly. Do not create per-task address definitions unless they are truly task-specific.

## Directory structure

Each task will have a directory structure similar to the following:

- **records/** Foundry will autogenerate files here from running commands
- **script/** place to store any one-off Foundry scripts
- **src/** place to store any one-off smart contracts (long-lived contracts should go in [base/contracts](https://github.com/base/contracts))
- **.env** place to store task-specific environment variables (contract addresses are inherited from the network-level `.env`)

## CI — Template Validation

A GitHub Actions workflow automatically validates all 10 setup-templates on every pull request and on pushes to `main`.

**What CI checks for each template:**

1. **Solidity formatting** — `forge fmt --check script/` ensures formatting consistency.
2. **Compilation** — `forge build` verifies that imports resolve, types are correct, and all dependencies are present.

Templates are validated in parallel using a matrix strategy, so failures are isolated per-template with clear error messages identifying the template and failure type.

**How it works:**

- Foundry stable is installed via the `foundry-rs/foundry-toolchain` GitHub Action.
- For each template, the corresponding `make setup-*` target creates a task directory from the template.
- `make deps` installs all dependencies (including base-contracts at the commit pinned in the template's `.env`).

**What CI does NOT do:**

- Does not run `forge script` (requires RPC URLs, env vars, and hardware wallets).
- Does not run `forge test` (no test files exist in templates).
- Does not run signing or execution targets (they depend on network state and hardware wallets).

> See [`.github/workflows/validate-templates.yml`](.github/workflows/validate-templates.yml) for the full workflow definition.

## Using the incident response template

This template contains scripts that will help us respond to incidents efficiently.

To use the template during an incident:

1. Fill in the `.env` file with dependency commit numbers and any variables that need to be defined for the script you're running.
1. Delete the other scripts that are not being used so that you don't run into build issues.
1. Make sure the code compiles and check in the code.
1. Have each signer pull the branch, and run the relevant signing command from the Makefile.

To add new incident response scripts:

1. Any incident response-related scripts should be included in this template (should be generic, not specific to network), with specific TODOs wherever addresses or other details need to be filled in.
1. Add the relevant make commands that would need to be run for the script to the template Makefile
1. Add relevant mainnet addresses in comments to increase efficiency responding to an incident.

## Using the generic template

This template can be used to do contract calls, upgrades, or one-off deployments.

1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file
1. Run `make deps`
1. Put scripts in the `script` directory (see examples that are part of the template, for example, there is a file `BasicScript.s.sol`). See note below if running a task that requires a multisig to sign.
1. Call scripts from the Makefile (see examples in the template Makefile that's copied over).

## Using the gas limit increase template

This template is increasing the throughput on Base Chain.

1. Ensure you have followed the instructions above in `setup`
1. Go to the folder that was created using the `make setup-gas-increase network=<network>` step
1. Fill in all TODOs (search for "TODO" in the folder) in the `.env` and `README` files. Tip: you can run `make deps` followed by `make sign-upgrade` to produce a Tenderly simulation which will help fill in several of the TODOs in the README (and also `make sign-rollback`).
1. Check in the task when it's ready to sign and collect signatures from signers
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the combined gas limit, elasticity, and DA footprint gas scalar template

This template is used to update the gas limit, elasticity, and DA footprint gas scalar, or roll back the changes (if needed).

1. Ensure you have followed the instructions above in `setup`, including running `make setup-gas-and-elasticity-increase network=<network>` and then go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) in the `.env` file.
1. Run `make deps`.
1. Fill in any task-specific variables in the `.env` file that have per-network comments (e.g., `OWNER_SAFE`, `SENDER`), using the value for your target network.
1. Ensure the `SENDER` variable in the `.env` file is set to a signer of `OWNER_SAFE`.
1. Set the `FROM_*` and `TO_*` values for gas limit and elasticity in the `.env` file.
1. Calculate the DA footprint gas scalar with `make da-scalar TARGET_BLOB_COUNT=<value>` and set the `FROM_DA_FOOTPRINT_GAS_SCALAR` and `TO_DA_FOOTPRINT_GAS_SCALAR` values in the `.env` file.
1. Build the contracts with `forge build`.
1. Generate the validation file for signers with `make gen-validation`.
1. Generate the rollback validation file for signers with `make gen-validation-rollback`.
1. Double check the `cmd` field at the top of both of the generated validation files and ensure that the value passed to the `--sender` flag matches the `SENDER` env var already defined in the `.env` file.
1. Ensure that all of the fields marked as `TODO` in the tasks's `README.md` have been properly filled out.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the fault proof upgrade template

This template is used to upgrade the fault proof contracts. This is commonly done in conjunction with a hard fork.

1. Ensure you have followed the instructions above in `setup`
1. Go to the folder that was created using the `make setup-upgrade-fault-proofs network=<network>` step
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file
1. Run `make deps`
1. Add the new absolute prestate to the `.env` file. This can be found in the op-program prestates [releases.json](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml) file.
1. Network-specific contract addresses are loaded automatically from the network `.env` file. Fill in any remaining task-specific variables in the task's `.env` file.
1. Build the contracts with `forge build`
1. Remove the unneeded validations from `VALIDATION.md` and update the relevant validations accordingly
1. Check in the task when it's ready to sign and collect signatures from signers
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the safe management template

This template is used to perform ownership management on a Gnosis Safe, like the incident multisig, specifically it can be used to change the owners of the multisig.

1. Ensure you have followed the instructions above in `setup`, including running `make setup-safe-management network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Enter the directory that was generated for the task (in the first step) and then run `make deps`.
1. Specify the `OWNER_SAFE`, which is the safe multisig where an owner will be replaced and the `SENDER` which should be the address of a current signer of the multisig.
1. Fill in the `OwnerDiff.json` inside the task's directory with the addresses to add to, and remove from, the multisig in their respective fields.
1. Ensure that the `EXISTING_OWNERS_LENGTH` constant value inside the `script/UpdateSigners.s.sol` script is set appropriately, in particular that it equals the exact number of current members of the Incident Multisig Safe (prior to running the task).
1. Build the contracts with `forge build`.
1. Generate the validation file for signers with `make gen-validation`.
1. Double check the `cmd` field at the top of the generated validation file at `validations/base-signer.json` and ensure that the value passed to the `--sender` flag matches the `SENDER` env var already defined in the `.env` file.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the funding template

This template is used to fund addresses from a Gnosis Safe.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-funding network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Specify the `SAFE`, which is the safe that will fund the addresses in the `.env` file.
1. Specify the `recipients` and `funds` arrays (in 1e18 units) in the `funding.json` file.
1. Build the contracts with `forge build`.
1. Simulate the task with `make sign` and update the generic validations in `VALIDATION.md` with the real values.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the Base Bridge set partner threshold template

This template is used to update the partner threshold in [Base Bridge](https://github.com/base/bridge), affecting the amount of required partner signatures to approve bridge messages.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-bridge-partner-threshold network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Fill in any task-specific variables in the `.env` file that have per-network comments, using the value for your target network.
1. Set the `NEW_THRESHOLD` variable in the `.env` file.
1. Ensure the `--sender` flag in the `make gen-validation` command in the `Makefile` file is set to a signer for `OWNER_SAFE` in `.env`.
1. Build the contracts with `forge build`.
1. Generate the validation file for signers with `make gen-validation`.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the pause Base Bridge template

This template is used to pause or un-pause [Base Bridge](https://github.com/base/bridge).

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-bridge-pause network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Fill in any task-specific variables in the `.env` file that have per-network comments (e.g., `L2_BRIDGE`), using the value for your target network.
1. Set the `IS_PAUSED` variable to `true` or `false` in the `.env` file depending on if you intend to pause or unpause the bridge.
1. Ensure the `--sender` flag in the `make gen-validation` command in the `Makefile` file is set to a signer for `OWNER_SAFE` in `.env`.
1. Build the contracts with `forge build`.
1. Generate the validation file for signers with `make gen-validation`.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the Switch to Permissioned Game template

This template is used to switch Base to a Permissioned Game.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-switch-to-permissioned-game network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Fill in any task-specific variables in the `.env` file that have per-network comments (e.g., `OWNER_SAFE`, `OP_SECURITY_COUNCIL_SAFE`, `SENDER`), using the value for your target network.
1. Build the contracts with `forge build`.
1. Generate the validation file for signers with `make gen-validation`.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.

## Using the pause SuperchainConfig template

This template is used to pause or un-pause the L1 SuperchainConfig contract.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-superchain-config-pause network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Fill in any task-specific variables in the `.env` file that have per-network comments, using the value for your target network.
1. Build the contracts with `forge build`.
1. Sign the pause transaction with `make sign-pause` or generate the validation file for un-pausing with `make gen-validation-unpause`.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `EXECUTED` in the README.
