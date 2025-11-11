# Contributing to contract-deployments

Thank you for your interest in contributing to this repository. This project contains deployment tasks and scripts for Base network operations. The repository is focused on deployment scripts, validation files, and task-specific scripts; actual contract implementations live in https://github.com/base-org/contracts.

This guide explains how to get started, run local checks, and submit a PR.

## Quick start

1. Fork the repo and clone it locally.
2. Create a branch for your change:

   git checkout -b docs/add-contributing

3. Implement your change, run local checks, and open a PR against `main`.

## Prerequisites

- Git
- Foundry (used for building and testing Solidity scripts)
- Go (for some tooling like `eip712sign`) — optional for most doc changes

Install Foundry quickly:

```sh
make install-foundry
```

## Running quick local checks

- Format check (Solidity):

  forge fmt --check

- Build (may require `.env` variables in some templates):

  forge build

Note: Running `make deps` will attempt to fetch repository-specific dependencies and requires `OP_COMMIT` and `BASE_CONTRACTS_COMMIT` to be set in a `.env` file. Do not add sensitive values to the repository.

## Creating task directories

To create a new task folder from a template use the Makefile helper commands (examples):

- Generic task:

  make setup-task network=mainnet task=example-task

- Gas increase task:

  make setup-gas-increase network=mainnet

Fill the generated `.env` and `VALIDATION.md` files before committing any task intended for signing/execution.

## PR checklist

- [ ] Branch off from `main` with a descriptive name
- [ ] Run `forge fmt --check` and `forge build` if relevant
- [ ] Keep changes scoped and add tests where applicable
- [ ] Add or update documentation when changing templates or scripts
- [ ] Do not commit private keys or real `.env` files

## Communication & Code of Conduct

If the change involves production signing workflows or multisig management, coordinate with maintainers before creating a PR. For security-sensitive issues, see `SECURITY.md`.

Thanks for helping improve the repository!
