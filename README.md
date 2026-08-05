![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base/contracts](https://github.com/base/contracts).

Active EVM tasks live under `active/evm/tasks/`. Shared network configuration lives under `config/`, and completed historical tasks live under `archive/`.

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

Each active task has its own `Makefile`, signer-facing `README.md`, facilitator
guide, task configuration, and validation files. Run task commands from that
task's directory:

```bash
cd active/evm/tasks/<task-id>
make deps
make <task-target>
```

Signers start the UI from the repository root with `make sign-task`, select the
network and task, then follow the task README.

## Network configuration

Shared network values live in `config/mainnet.env`, `config/sepolia.env`, and
`config/zeronet.env`. Task Makefiles include the appropriate shared file, while
`config/<network>/.env` inside the task contains only task-specific values such
as `BASE_CONTRACTS_COMMIT`.

## Directory structure

`active/evm` is one shared Foundry project. Common Solidity lives under
`script/common/`, dependencies are installed into `active/evm/lib`, and each
task owns its operational files:

```text
active/evm/
├── foundry.toml
├── script/common/
└── tasks/<YYYY-MM-DD-task-name>/
    ├── Makefile
    ├── FACILITATOR.md
    ├── config/<network>/
    │   ├── .env
    │   ├── README.md
    │   └── validations/
    └── signatures/<network>/
```

Reusable scripts are documented in
[`active/evm/script/common/README.md`](active/evm/script/common/README.md).

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

Task Makefiles use the shared macros in [`Multisig.mk`](Multisig.mk) for
validation generation, nested-Safe approvals, and execution. Tasks running from
their own directory set `FORGE_WORKDIR` to `active/evm` so Forge uses the shared
Foundry project and common scripts.

## Task origin signing

The root Makefile provides `sign-as-task-creator`,
`sign-as-base-facilitator`, and `sign-as-sc-facilitator`. Active task Makefiles
set `TASK_ORIGIN_DIR` to `config/<network>` and store signatures separately in
`signatures/<network>` so generating signatures does not change the signed
payload. Validation files may set `skipTaskOriginValidation: true` where task
origin validation is not required.
