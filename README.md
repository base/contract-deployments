![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base/contracts](https://github.com/base/contracts).

This repo is structured with each network having a high-level directory which contains subdirectories of any "tasks" (contract deployments/calls) that have happened for that network.

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

### Toolchain (mise)

All required tooling (Foundry, Node.js, Bun, Go) is pinned in [`mise.toml`](mise.toml) so that every contributor — and especially every signer — runs identical versions. This eliminates a class of bugs where domain separators, build artifacts, or generated signatures differ between machines.

**Signers and facilitators don't need to install anything.** `make sign-task` (and `make deps`, `make execute`, etc.) automatically:

1. Installs [`mise`](https://mise.jdx.dev) to `~/.local/bin/mise` if it's not already present, using the vendored installer at [`scripts/install-mise.sh`](scripts/install-mise.sh).
2. Trusts the repo's `mise.toml` and runs `mise install` to fetch the pinned `foundry`, `node`, `bun`, and `go` versions.
3. Invokes every toolchain command through `mise exec --`, so the pinned versions are used without modifying your shell environment or `PATH`. This deliberately avoids conflicts with any existing `foundryup` or system-level installs.

> **Important — `mise` must be on your PATH for the signer-tool.** The generated validation files contain a `cmd` field with `mise exec --` (deliberately, so the JSON is portable across machines), and the signer-tool re-executes that command in a fresh shell. If `mise` is not on your PATH, that subprocess will fail with "command not found". `make bootstrap-mise` will warn you if this is the case. To fix it, add this to your shell config (e.g. `~/.zshrc` or `~/.bashrc`) and restart your shell:
>
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```
>
> Alternatively, install `mise` system-wide so it lands on your default PATH.

#### Verifying the pinned Foundry version (optional)

```bash
$ mise exec -- forge --version
forge Version: 1.5.1-...
Commit SHA: b0a9dd9ceda36f63e2326ce530c10e6916f4b8a2
```

The `Commit SHA` is the source of truth — it must match the commit pinned in `mise.toml`.

#### For contributors authoring new tasks (optional)

If you want bare `forge`/`cast`/`bun`/`go` invocations in your interactive shell to resolve to the pinned versions while you're working inside this repo, add mise's shell hook to your shell config:

```bash
# zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

This is purely a convenience for task authors — `make` targets work correctly without it.

### Running a task

Active EVM work lives under `active/evm`. Network-specific config lives under `active/evm/tasks/<task-id>/config/<network>`, and reusable scripts live under `active/evm/script/common/<category>`.

For the current active task:

```bash
cd active/evm
make deps
make sign-task
```

For non-default active EVM task or network config, pass `TASK_ID=<task-id>` and `TASK_NETWORK=<network>` to task targets.

Common scripts are documented in [`active/evm/script/common/README.md`](active/evm/script/common/README.md). If a script will be used regularly, put it under the appropriate category folder in `script/common/`; keep one-off task-specific scripts outside `common/`.

## Network configuration

Legacy task history lives under `archive/legacy/`. The active EVM task layout keeps network-specific configuration under `active/evm/tasks/<task-id>/config/<network>/`.

Each active network config contains a `.env` file for task-specific values and a `network.env` file for contract addresses and network metadata. The active EVM Makefile loads these with `TASK_ID=2026-06-18-beryl-1` and `TASK_NETWORK=mainnet` by default:

```makefile
include $(TASK_DIR)/config/$(TASK_NETWORK)/network.env
include $(TASK_DIR)/config/$(TASK_NETWORK)/.env
```

For other active tasks, demo configs, or testnet configs, pass `TASK_ID=<task-id>` and `TASK_NETWORK=<network>` when invoking active task targets.

The network `network.env` files contain:

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

## Multisig macro convention

Task Makefiles should use global macros defined in [`Multisig.mk`](Multisig.mk) for multisig operations:

| Macro              | Purpose                                                         | Key arguments                                             |
| ------------------ | --------------------------------------------------------------- | --------------------------------------------------------- |
| `MULTISIG_APPROVE` | Approve a transaction (nested safe hierarchy)                   | `(address_list, signatures)`                              |
| `MULTISIG_EXECUTE` | Execute an approved transaction on-chain                        | `(signatures)`                                            |
| `GEN_VALIDATION`   | Generate a validation JSON file for signers via the signer-tool | `(script_name, safe_addr, sender, output_file, env_vars)` |

Two helper macros are also available for tasks that need nonce offset calculations or address manipulation:

| Macro        | Purpose                                                    | Key arguments    |
| ------------ | ---------------------------------------------------------- | ---------------- |
| `GET_NONCE`  | Fetch the current nonce of a Safe contract on-chain        | `(safe_address)` |
| `ADDR_UPPER` | Convert an address to uppercase (for env var construction) | `(address)`      |

Signing is handled externally by the [task-signing-tool](https://github.com/base/task-signing-tool).

Every task Makefile should include `Multisig.mk` and define at least two variables for the macros to work:

```makefile
include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)       # or $(L2_RPC_URL)
SCRIPT_NAME = MyScript         # class name or .sol file path
```

Tasks that generate validation files should use `GEN_VALIDATION` with the `deps-signer-tool` prerequisite (which checks out and installs the signer-tool):

```makefile
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)
```

Tasks should use these macros rather than inline `forge script` / `eip712sign` / `bun run` invocations unless the task needs a bespoke emergency flow.

## Task origin signing

The root Makefile provides three targets for generating cryptographic attestations (sigstore bundles) that prove who created and facilitated a task. These are inherited by all task Makefiles via `include ../../Makefile`.

| Target                          | Purpose                                         |
| ------------------------------- | ----------------------------------------------- |
| `make sign-as-task-creator`     | Attest authorship of the task (run after setup) |
| `make sign-as-base-facilitator` | Attest Base team facilitation                   |
| `make sign-as-sc-facilitator`   | Attest Security Council facilitation            |

Legacy task directories store signatures in `<network>/signatures/<task-name>/`, where `<task-name>` is auto-derived from the task directory name. The active EVM layout overrides this and stores task origin signatures with the selected network config:

```text
active/evm/tasks/<task-id>/config/<network>/signatures/
```

The task origin folder is `active/evm/tasks/<task-id>/config/<network>`. The signer tool excludes the nested `signatures/` directory from the task-origin tarball, so generating signatures does not change the signed payload. Two variables control this behavior and can be overridden in a task's Makefile if the defaults are not appropriate:

| Variable        | Default                                    | Description                           |
| --------------- | ------------------------------------------ | ------------------------------------- |
| `TASK_NAME`     | `$(notdir $(CURDIR))` (directory basename) | Name used to locate signature dir     |
| `SIGNATURE_DIR` | `$(CURDIR)/../signatures/$(TASK_NAME)`     | Directory where signatures are stored |

The active EVM Makefile also overrides `TASK_ORIGIN_DIR` to `$(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)`.

All three targets depend on `deps-signer-tool`, which checks out and installs the [task-signing-tool](https://github.com/base/task-signing-tool) automatically.
