![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see
[base/contracts](https://github.com/base/contracts).

Active EVM tasks live under `active/evm/tasks/`. Shared network configuration lives under `config/`, and completed historical tasks live under
`archive/`.

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

All required tooling (Foundry, Node.js, Bun, Go) is pinned in [`mise.toml`](mise.toml) so that every contributor — and especially every signer — runs
identical versions. This eliminates a class of bugs where domain separators, build artifacts, or generated signatures differ between machines.

**Signers and facilitators don't need to install anything.** `make sign-task` (and `make deps`, `make execute`, etc.) automatically:

1. Installs [`mise`](https://mise.jdx.dev) to `~/.local/bin/mise` if it's not already present, using the vendored installer at
   [`scripts/install-mise.sh`](scripts/install-mise.sh).
2. Trusts the repo's `mise.toml` and runs `mise install` to fetch the pinned `foundry`, `node`, `bun`, and `go` versions.
3. Invokes every toolchain command through `mise exec --`, so the pinned versions are used without modifying your shell environment or `PATH`. This
   deliberately avoids conflicts with any existing `foundryup` or system-level installs.

> **Important — `mise` must be on your PATH for the signer-tool.** The generated validation files contain a `cmd` field with `mise exec --`
> (deliberately, so the JSON is portable across machines), and the signer-tool re-executes that command in a fresh shell. If `mise` is not on your
> PATH, that subprocess will fail with "command not found". `make bootstrap-mise` will warn you if this is the case. To fix it, add this to your shell
> config (e.g. `~/.zshrc` or `~/.bashrc`) and restart your shell:
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

If you want bare `forge`/`cast`/`bun`/`go` invocations in your interactive shell to resolve to the pinned versions while you're working inside this
repo, add mise's shell hook to your shell config:

```bash
# zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

This is purely a convenience for task authors — `make` targets work correctly without it.

### Running a task

Each active task owns its Makefile, signer README, facilitator guide, configuration, and validations. Run task commands from the task directory:

```bash
cd active/evm/tasks/<task-id>
make deps
make <task-target>
```

Signers run `make sign-task` from the repository root, select the network and task in the UI, and follow the task README.

## Network configuration

Shared network values live in `config/mainnet.env`, `config/sepolia.env`, and `config/zeronet.env`. Task Makefiles include the appropriate shared file
and load operation-specific values from `config/<network>/.env` inside the task.

The network `.env` files contain:

- **Network metadata** — `NETWORK`, `L1_RPC_URL`, `L2_RPC_URL`, `L1_CHAIN_ID`, `L2_CHAIN_ID`, `LEDGER_ACCOUNT`
- **Admin addresses** — multisig addresses, proposer, challenger, batch sender, etc.
- **L1 contract addresses** — proxy admin, bridges, dispute game factories, system config, etc.
- **L2 contract addresses** — fee vaults, cross-domain messenger, standard bridge, etc.

All address variables are prefixed with `export` so they are available to child shell processes (Forge scripts, shell commands, etc.). Foundry scripts
can access them via `vm.envAddress("VARIABLE_NAME")`.

> **Note:** Update `config/<network>.env` when a known shared address changes. Keep task-specific values, including `BASE_CONTRACTS_COMMIT`, in the
> task `.env`.

## Directory structure

Active EVM tasks use one shared Foundry project. Dependencies and reusable Solidity are shared; Make targets, configuration, documentation,
signatures, and execution records stay with each task:

```text
active/evm/
├── foundry.toml                 # shared Foundry config (base-contracts v8.2.1)
├── lib/                         # generated shared dependencies; not committed
├── script/
│   └── common/                  # reusable scripts, shared across tasks
│       └── <category>/          # bridge, funding, gas, ownership, safe, superchain, verifier-update
└── tasks/
    └── <YYYY-MM-DD-task-name>/
        ├── Makefile             # task dependencies, validation, approvals, execution
        ├── FACILITATOR.md       # facilitator runbook
        ├── config/
        │   └── <network>/
        │       ├── .env         # task inputs + BASE_CONTRACTS_COMMIT
        │       ├── README.md    # status + description (parsed by the signer tool)
        │       └── validations/ # generated per-signer validation JSON
        ├── signatures/
        │   └── <network>/       # task-origin signatures (when required)
        └── <script>/<chain-id>/ # Forge broadcast records after execution
```

Task commands run from `active/evm/tasks/<task-id>`. The task Makefile installs dependencies and runs Forge against the shared `active/evm` project.
Reusable scripts are documented in [`active/evm/script/common/README.md`](active/evm/script/common/README.md).

To install dependencies for the shared project without selecting a task, invoke the root Makefile with a project directory and explicit commit:

```bash
make deps PROJECT_DIR="$PWD/active/evm" BASE_CONTRACTS_COMMIT=<commit>
```

### Legacy tasks

Each task under `archive/legacy/<network>/` has a structure similar to:

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

- All tooling (Foundry, Node, Bun, Go) is installed by the [`jdx/mise-action`](https://github.com/jdx/mise-action) GitHub Action using the versions
  pinned in [`mise.toml`](mise.toml), so CI matches local signer environments.
- `make deps PROJECT_DIR="$PWD/active/evm"` installs dependencies into the shared `active/evm` Foundry project. `BASE_CONTRACTS_COMMIT` is supplied
  via the workflow's `env` block, since the shared project has no task `.env` of its own.
- `forge fmt --check` and `forge build` then run in `active/evm` against the shared `foundry.toml` and `script/common/`.

**What CI does NOT do:**

- Does not run `forge script` (requires RPC URLs, env vars, and hardware wallets).
- Does not run `forge test` (no test files exist for these scripts).
- Does not run signing or execution targets (they depend on network state and hardware wallets).

> See [`.github/workflows/validate-common-scripts.yml`](.github/workflows/validate-common-scripts.yml) for the full workflow definition.

## Multisig macro convention

Task Makefiles use global macros defined in [`Multisig.mk`](Multisig.mk) for multisig operations:

| Macro              | Purpose                                                         | Key arguments                                             |
| ------------------ | --------------------------------------------------------------- | --------------------------------------------------------- |
| `MULTISIG_APPROVE` | Approve a transaction (nested safe hierarchy)                   | `(address_list, signatures)`                              |
| `MULTISIG_EXECUTE` | Execute an approved transaction onchain                         | `(signatures)`                                            |
| `GEN_VALIDATION`   | Generate a validation JSON file for signers via the signer-tool | `(script_name, safe_addr, sender, output_file, env_vars)` |

Two helper macros are also available for tasks that need nonce offset calculations or address manipulation:

| Macro        | Purpose                                                    | Key arguments    |
| ------------ | ---------------------------------------------------------- | ---------------- |
| `GET_NONCE`  | Fetch the current nonce of a Safe contract onchain         | `(safe_address)` |
| `ADDR_UPPER` | Convert an address to uppercase (for env var construction) | `(address)`      |

Signing is handled externally by the [task-signing-tool](https://github.com/base/task-signing-tool).

Each task Makefile includes the root helpers, points Forge at the shared EVM project, and defines the RPC and script:

```makefile
include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

PROJECT_DIR := $(abspath ../..)
FORGE_WORKDIR := $(PROJECT_DIR)
RPC_URL := $(L1_RPC_URL)       # or $(L2_RPC_URL)
SCRIPT_NAME := script/common/<category>/<script>.s.sol:<contract>
```

Tasks that generate validation files should use `GEN_VALIDATION` with the `deps-signer-tool` prerequisite, which checks out and installs the signer
tool:

```makefile
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)
```

Task Makefiles should use these macros rather than inline `forge script` or signer-tool invocations. A task that intentionally pre-signs several
future nonces may keep its specialized `eip712sign` loop locally; approvals and execution should still use the shared macros.

## Task origin signing

The root Makefile provides three targets for generating cryptographic attestations that prove who created and facilitated a task. Active task
Makefiles inherit them by including the root Makefile.

| Target                          | Purpose                                         |
| ------------------------------- | ----------------------------------------------- |
| `make sign-as-task-creator`     | Attest authorship of the task (run after setup) |
| `make sign-as-base-facilitator` | Attest Base team facilitation                   |
| `make sign-as-sc-facilitator`   | Attest Security Council facilitation            |

Legacy task Makefiles may use the root defaults below. Active task Makefiles override them so the task configuration is signed while signatures remain
outside the signed payload:

| Variable        | Default                                    | Description                           |
| --------------- | ------------------------------------------ | ------------------------------------- |
| `TASK_NAME`     | `$(notdir $(CURDIR))` (directory basename) | Name used to locate signature dir     |
| `SIGNATURE_DIR` | `$(CURDIR)/../signatures/$(TASK_NAME)`     | Directory where signatures are stored |

All three targets depend on `deps-signer-tool`, which checks out and installs the [task-signing-tool](https://github.com/base/task-signing-tool)
automatically.

For active EVM tasks, `TASK_ORIGIN_DIR` is `active/evm/tasks/<task-id>/config/<network>` and `SIGNATURE_DIR` is
`active/evm/tasks/<task-id>/signatures/<network>`. Keeping signatures outside the config directory means generating them does not change the signed
payload. Task-origin validation is required for mainnet scripts executed through the proxy admin owner. Other tasks, such as Zeronet tasks, may set
`skipTaskOriginValidation: true` in each validation file.
