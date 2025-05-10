![Base](logo.webp)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base-org/contracts](https://github.com/base-org/contracts).

This repo is structured with each network having a high-level directory which contains subdirectories of any "tasks" (contract deployments/calls) that have happened for that network.

<!-- Badge row 1 - status -->

[![GitHub contributors](https://img.shields.io/github/contributors/base-org/contract-deployments)](https://github.com/base-org/contract-deployments/graphs/contributors)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/w/base-org/contract-deployments)](https://github.com/base-org/contract-deployments/graphs/contributors)
[![GitHub Stars](https://img.shields.io/github/stars/base-org/contract-deployments.svg)](https://github.com/base-org/contract-deployments/stargazers)
![GitHub repo size](https://img.shields.io/github/repo-size/base-org/contract-deployments)
[![GitHub](https://img.shields.io/github/license/base-org/contract-deployments?color=blue)](https://github.com/base-org/contract-deployments/blob/main/LICENSE)

<!-- Badge row 2 - links and profiles -->

[![Website base.org](https://img.shields.io/website-up-down-green-red/https/base.org.svg)](https://base.org)
[![Blog](https://img.shields.io/badge/blog-up-green)](https://base.mirror.xyz/)
[![Docs](https://img.shields.io/badge/docs-up-green)](https://docs.base.org/)
[![Discord](https://img.shields.io/discord/1067165013397213286?label=discord)](https://base.org/discord)
[![Twitter BuildOnBase](https://img.shields.io/twitter/follow/BuildOnBase?style=social)](https://twitter.com/BuildOnBase)

<!-- Badge row 3 - detailed status -->

[![GitHub pull requests by-label](https://img.shields.io/github/issues-pr-raw/base-org/contract-deployments)](https://github.com/base-org/contract-deployments/pulls)
[![GitHub Issues](https://img.shields.io/github/issues-raw/base-org/contract-deployments.svg)](https://github.com/base-org/contract-deployments/issues)

## Setup

First, install forge if you don't have it already:

- Run `make install-foundry` to install [`Foundry`](https://github.com/foundry-rs/foundry/commit/3b1129b5bc43ba22a9bcf4e4323c5a9df0023140).

To execute a new task, run one of the following commands (depending on the type of change you're making):

- For incident response commands: `make setup-incident network=<network> incident=<incident-name>`
- For gas increase commands: `make setup-gas-increase network=<network>`
- For full new deployment (of L1 contracts related to Base): `make setup-deploy network=<network>`
- For fault proof upgrade: `make setup-upgrade-fault-proofs network=<network>`
- For contract calls, upgrades, or one-off contract deployments: `make setup-task network=<network> task=<task-name>`

Next, `cd` into the directory that was created for you and follow the steps listed below for the relevant template.

## Directory structure

Each task will have a directory structure similar to the following:

- **[inputs/](/inputs)** any input JSON files
- **[records/](/records)** Foundry will autogenerate files here from running commands
- **[script/](/script)** place to store any one-off Foundry scripts
- **[src/](/src)** place to store any one-off smart contracts (long-lived contracts should go in [base-org/contracts](https://github.com/base-org/contracts))
- **.env** place to store environment variables specific to this task

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

## Using the deploy template

This template is used for deploying the L1 contracts in the OP stack to set up a new network.

1. Ensure you have followed the instructions above in `setup`
1. Rename the folder to something more descriptive
1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base-org/contracts) you intend to use in the `.env` file
1. Run `make deps`
1. Fill in the `inputs/deploy-config.json` and `inputs/misc-config.json` files with the input variables for the deployment.
1. See the example `make deploy` command. Modifications may need to be made if you're using a key for deployment that you do not have the private key for (e.g. a hardware wallet)
1. Run `make deploy` command
1. Check in files to GitHub. The files to ignore should already have been specified in the `.gitignore`, so you should be able to check in everything.

## Using the gas limit increase template

This template is increasing the throughput on Base Chain.

1. Ensure you have followed the instructions above in `setup`
1. Go to the folder that was created using the `make setup-gas-increase network=<network>` step
1. Fill in all TODOs (search for "TODO" in the folder) in the `.env` and `README` files. Tip: you can run `make deps` followed by `make sign-upgrade` to produce a Tenderly simulation which will help fill in several of the TODOs in the README (and also `make sign-rollback`).
1. Check in the task when it's ready to sign and collect signatures from signers
1. Once executed, check in the records files and mark the task `DONE` in the README.

## Using the fault proof upgrade template

This template is used to upgrade the fault proof contracts. This is commonly done in conjunction with a hardfork.

1. Ensure you have followed the instructions above in `setup`
1. Go to the folder that was created using the `make setup-upgrade-fault-proofs network=<network>` step
1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base-org/contracts) you intend to use in the `.env` file
1. Run `make deps`
1. Add the new absolute prestate to the `.env` file. This can be found in the op-program prestates [releases.json](https://github.com/ethereum-optimism/optimism/blob/develop/op-program/prestates/releases.json) file.
1. NOTE: If this task is for mainnet, the directory should work as-is. If this task is for testnet, you will need to follow the following steps:
   1. Update the `UpgradeDGF` script to inherit `MultisigBuilder` instead of `NestedMultisigBuilder`
   1. Comment out the mainnet environment variables and uncomment the testnet vars in `.env`
   1. Comment out the nested multisig builder commands in the Makefile and uncomment the multisig builder commands
1. Build the contracts with `forge build`
1. Remove the unneeded validations from `VALIDATION.md` and update the relevant validations accordingly
1. Check in the task when it's ready to sign and collect signatures from signers
1. Once executed, check in the records files and mark the task `DONE` in the README.

## Using the swap owner template

This template is used to perform ownership management on a Gnosis Safe multisig, specifically it can swap owners on the multisig.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-safe-management network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base-org/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Specify the `OWNER_SAFE`, which is the safe multisig where an owner will be replaced, the `OLD_SIGNER` (current owner) to remove, and the `NEW_SIGNER` (new owner) to be added in the `.env` file.
1. Build the contracts with `forge build`.
1. Simulate the task with `make sign` and update the generic validations in `VALIDATION.md` with the real values.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `DONE` in the README.

## Using the funding template

This template is used to fund addresses from a Gnosis Safe.

1. Ensure you have followed the instructions above in `setup`.
1. Run `make setup-funding network=<network>` and go to the folder that was created by this command.
1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base/contracts) you intend to use in the `.env` file.
1. Run `make deps`.
1. Specify the `SAFE`, which is the safe that will fund the addresses in the `.env` file.
1. Specify the `recipients` and `funds` arrays (in 1e18 units) in the `funding.json` file.
1. Build the contracts with `forge build`.
1. Simulate the task with `make sign` and update the generic validations in `VALIDATION.md` with the real values.
1. Check in the task when it's ready to sign and request the facilitators to collect signatures from signers.
1. Once executed, check in the records files and mark the task `DONE` in the README.

## Using the generic template

This template can be used to do contract calls, upgrades, or one-off deployments.

1. Specify the commit of [Optimism code](https://github.com/ethereum-optimism/optimism) and [Base contracts code](https://github.com/base-org/contracts) you intend to use in the `.env` file
1. Run `make deps`
1. Put scripts in the `scripts` directory (see examples that are part of the template, for example, there is a file `TransferOwner.s.sol`, which can be used to set up the ownership transfer task). See note below if running a task that requires a multisig to sign.
1. Call scripts from the Makefile (see examples in the template Makefile that's copied over).

Note: If using a multisig as a signer, you can leverage the `MultisigBuilder` for standard multisigs or the `NestedMultisigBuilder` scripts in the [base contracts repo](https://github.com/base-org/contracts/tree/main/script/universal) for multisigs that contain other multisigs as signers. For these scripts, you need to implement the virtual functions that are provided, which will allow you to configure the task you'd like to run, the address of the multisig you're running it from, and any post-execution checks. See the files themselves for more details. It is recommended to add any configured addresses as constants at the top of the file and provide links to Etherscan, etc., as needed for reviewers to more accurately review the PR.
