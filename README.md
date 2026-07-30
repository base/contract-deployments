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

New EVM tasks are created under [`active/evm/tasks/<task-id>/`](#directory-structure)
and reference a reusable script from
[`active/evm/script/common/<category>/`](active/evm/script/common) rather than
copying a standalone template project. See the
[Common operation scripts](#common-operation-scripts) table below to find the
script for your change, and [`active/evm/script/common/README.md`](active/evm/script/common/README.md)
for the full inventory and conventions.

To set up a task, create `active/evm/tasks/<YYYY-MM-DD-task-name>/config/<network>/`
with its `.env`, `network.env`, `README.md`, and `validations/` (see the layout in
[Directory structure](#directory-structure)), then run task commands from
`active/evm` selecting the task with `TASK_ID` / `TASK_NETWORK`. Validation files
for signers are produced with `make gen-validation-*`, and task-origin signatures
(when required) with the [task-origin signing](#task-origin-signing) targets.

## Network configuration

Each network directory (`mainnet/`, `sepolia/`, `sepolia-alpha/`, `zeronet/`) contains a `.env` file that defines all contract addresses and network metadata for that chain. These variables are automatically available to every task via the `include ../.env` directive in each task's Makefile, so there is no need to manually load addresses in individual tasks or templates.

The network `.env` files contain:

- **Network metadata** — `NETWORK`, `L1_RPC_URL`, `L2_RPC_URL`, `L1_CHAIN_ID`, `L2_CHAIN_ID`, `LEDGER_ACCOUNT`
- **Admin addresses** — multisig addresses, proposer, challenger, batch sender, etc.
- **L1 contract addresses** — proxy admin, bridges, dispute game factories, system config, etc.
- **L2 contract addresses** — fee vaults, cross-domain messenger, standard bridge, etc.

All address variables are prefixed with `export` so they are available to child shell processes (Forge scripts, shell commands, etc.). Foundry scripts can access them via `vm.envAddress("VARIABLE_NAME")`.

> **Note:** If you need to add or update a contract address, edit the corresponding `{network}/.env` file directly. Do not create per-task address definitions unless they are truly task-specific.

## Directory structure

Active EVM tasks live under `active/evm/`, which is a single shared Foundry
project rather than a standalone project per task. A single `active/evm/Makefile`
selects the active task via `TASK_ID` / `TASK_NETWORK`, reusable operation
scripts are shared across tasks under `script/common/<category>/`, and each task
directory holds only its own config, docs, and (per-network) validations and
signatures:

```text
active/evm/
├── Makefile                     # shared; selects the task via TASK_ID / TASK_NETWORK
├── foundry.toml                 # shared Foundry config (base-contracts v8.2.1)
├── script/
│   └── common/                  # reusable scripts, shared across tasks
│       └── <category>/          # bridge, funding, gas, ownership, safe, superchain, verifier-update
└── tasks/
    └── <YYYY-MM-DD-task-name>/
        ├── FACILITATOR.md
        ├── config/
        │   └── <network>/
        │       ├── .env         # task inputs + BASE_CONTRACTS_COMMIT + RECORD_STATE_DIFF
        │       ├── network.env  # RPC, chain ids, Safe/contract addresses
        │       ├── README.md    # status + description (parsed by the signer tool)
        │       └── validations/ # generated per-signer validation JSON
        └── signatures/
            └── <network>/       # task-origin signatures (when required)
```

Task commands run from `active/evm`, selecting the task by `TASK_ID` /
`TASK_NETWORK` (both default to the current task in the shared `Makefile`), e.g.
`TASK_ID=<task> TASK_NETWORK=<network> make gen-validation-cb`. The shared
Makefile runs Forge from `active/evm` using the shared `foundry.toml` and `lib/`,
while task-specific files are read from `tasks/<task-id>/config/<network>/`.
Reusable scripts are documented in [`active/evm/script/common/README.md`](active/evm/script/common/README.md);
put a script under `script/common/<category>/` when it will be reused across
tasks, and keep one-off task glue out of `common/`.

The shared `active/evm/Makefile` selects a task (via `TASK_ID` / `TASK_NETWORK`)
and sources that task's `.env` for `BASE_CONTRACTS_COMMIT`. To install
dependencies for the shared project without selecting a task (e.g. to build the
common scripts locally), invoke the root Makefile directly with a `PROJECT_DIR`
override and an explicit `BASE_CONTRACTS_COMMIT`:

```bash
make deps PROJECT_DIR="$PWD/active/evm" BASE_CONTRACTS_COMMIT=<commit>
```

### Legacy tasks

Each legacy task (under a network directory, or `archive/legacy/`) has a directory structure similar to the following:

- **records/** Foundry will autogenerate files here from running commands
- **script/** place to store any one-off Foundry scripts
- **src/** place to store any one-off smart contracts (long-lived contracts should go in [base/contracts](https://github.com/base/contracts))
- **.env** place to store task-specific environment variables (contract addresses are inherited from the network-level `.env`)

## CI — Common Script Validation

A GitHub Actions workflow automatically validates the shared `active/evm` scripts on every pull request and on pushes to `main`.

**What CI checks:**

1. **Solidity formatting** — `forge fmt --check script/` ensures formatting consistency.
2. **Compilation** — `forge build` verifies that imports resolve, types are correct, and all dependencies are present.

**How it works:**

- All tooling (Foundry, Node, Bun, Go) is installed by the [`jdx/mise-action`](https://github.com/jdx/mise-action) GitHub Action using the versions pinned in [`mise.toml`](mise.toml), so CI matches local signer environments.
- `make deps PROJECT_DIR="$PWD/active/evm"` installs dependencies into the shared `active/evm` Foundry project. `BASE_CONTRACTS_COMMIT` is supplied via the workflow's `env` block, since the shared project has no task `.env` of its own.
- `forge fmt --check` and `forge build` then run in `active/evm` against the shared `foundry.toml` and `script/common/`.

**What CI does NOT do:**

- Does not run `forge script` (requires RPC URLs, env vars, and hardware wallets).
- Does not run `forge test` (no test files exist for these scripts).
- Does not run signing or execution targets (they depend on network state and hardware wallets).

> See [`.github/workflows/validate-common-scripts.yml`](.github/workflows/validate-common-scripts.yml) for the full workflow definition.

## Multisig macro convention

All task templates use global macros defined in [`Multisig.mk`](Multisig.mk) for multisig operations:

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

Every template Makefile should include `Multisig.mk` and define at least two variables for the macros to work:

```makefile
include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)       # or $(L2_RPC_URL)
SCRIPT_NAME = MyScript         # class name or .sol file path
```

Templates that generate validation files should use `GEN_VALIDATION` with the `deps-signer-tool` prerequisite (which checks out and installs the signer-tool):

```makefile
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)
```

Templates should use these macros rather than inline `forge script` / `eip712sign` / `bun run` invocations. The known exceptions are the incident-response pause templates, which pre-sign 20 future nonces in a loop using inline `eip712sign`; only their `execute-*` targets use `MULTISIG_EXECUTE`.

## Task origin signing

The root Makefile provides three targets for generating cryptographic attestations (sigstore bundles) that prove who created and facilitated a task. These are inherited by all task Makefiles via `include ../../Makefile`.

| Target                          | Purpose                                         |
| ------------------------------- | ----------------------------------------------- |
| `make sign-as-task-creator`     | Attest authorship of the task (run after setup) |
| `make sign-as-base-facilitator` | Attest Base team facilitation                   |
| `make sign-as-sc-facilitator`   | Attest Security Council facilitation            |

Signatures are stored in `<network>/signatures/<task-name>/`, where `<task-name>` is auto-derived from the task directory name. This directory is created automatically when you run any `setup-*` target (in both the root and Solana Makefiles), so it is ready for the signing tool when you invoke one of the targets below. Two variables control this behavior and can be overridden in a task's Makefile if the defaults are not appropriate:

| Variable        | Default                                    | Description                           |
| --------------- | ------------------------------------------ | ------------------------------------- |
| `TASK_NAME`     | `$(notdir $(CURDIR))` (directory basename) | Name used to locate signature dir     |
| `SIGNATURE_DIR` | `$(CURDIR)/../signatures/$(TASK_NAME)`     | Directory where signatures are stored |

All three targets depend on `deps-signer-tool`, which checks out and installs the [task-signing-tool](https://github.com/base/task-signing-tool) automatically.

For `active/evm` tasks, the shared Makefile overrides `TASK_ORIGIN_DIR` and `SIGNATURE_DIR`: the signer tool signs over the `active/evm/tasks/<task-id>/config/<network>` directory (`TASK_ORIGIN_DIR`), while the signatures themselves are written to `active/evm/tasks/<task-id>/signatures/<network>/` (`SIGNATURE_DIR`) — outside the signed directory, so generating signatures does not change the signed payload. A task may opt out of task-origin validation entirely by setting `skipTaskOriginValidation: true` at the root of each validation file (e.g. non-production networks such as zeronet).

## Common operation scripts

The reusable operation scripts that used to be copied from `setup-templates/` now
live under [`active/evm/script/common/<category>/`](active/evm/script/common) and
are shared across tasks in the [`active/evm`](#directory-structure) project. A new
task references one of these scripts from its own `active/evm/tasks/<task-id>/`
config and Makefile rather than copying a standalone template project. See
[`active/evm/script/common/README.md`](active/evm/script/common/README.md) for the
full inventory and usage.

| Former `setup-templates/` template | Common script |
| --- | --- |
| `template-gas-increase`, `template-gas-and-elasticity-increase` | [`gas/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol`](active/evm/script/common/gas/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol) |
| `template-safe-management` | [`safe/UpdateSigners.s.sol`](active/evm/script/common/safe/UpdateSigners.s.sol) |
| `template-funding` | [`funding/Fund.s.sol`](active/evm/script/common/funding/Fund.s.sol) |
| `template-set-bridge-partner-threshold` | [`bridge/SetThreshold.s.sol`](active/evm/script/common/bridge/SetThreshold.s.sol) |
| `template-pause-bridge-base` | [`bridge/PauseBridge.s.sol`](active/evm/script/common/bridge/PauseBridge.s.sol) |
| `template-pause-superchain-config` | [`superchain/PauseSuperchainConfig.s.sol`](active/evm/script/common/superchain/PauseSuperchainConfig.s.sol) |
