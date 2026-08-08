![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base/contracts](https://github.com/base/contracts).

Current EVM tasks and shared tooling live under `active/evm/`. Historical tasks
are grouped by network under `archive/legacy/`.

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

`make sign-task` (and `make deps`, `make execute`, etc.) bootstraps the pinned
toolchain automatically:

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

### Active EVM tasks

[`active/evm/tasks/README.md`](active/evm/tasks/README.md) is the task-authoring
and execution guide. [`active/evm/script/common/README.md`](active/evm/script/common/README.md)
lists the reusable Solidity operations.

```bash
make -C active/evm TASK_ID=<task> TASK_NETWORK=<network> gen-validation
```

Reusable workflows use the multisig helpers documented in [`Multisig.mk`](Multisig.mk).
Signing is handled by the [task-signing-tool](https://github.com/base/task-signing-tool).

### Legacy tasks

Each task under `archive/legacy/<network>/` has a structure similar to:

- **records/** Foundry will autogenerate files here from running commands
- **script/** place to store any one-off Foundry scripts
- **src/** place to store any one-off smart contracts (long-lived contracts should go in [base/contracts](https://github.com/base/contracts))
- **.env** place to store task-specific environment variables (contract addresses are inherited from the network-level `.env`)

## CI

CI formats and builds the shared Solidity and checks the Make dispatcher. It
does not sign or execute tasks. See
[`.github/workflows/validate-common-scripts.yml`](.github/workflows/validate-common-scripts.yml).

## Task origin signing

The root Makefile provides three targets for generating cryptographic
attestations that prove who created and facilitated a task. Legacy task
Makefiles and the active EVM dispatcher inherit these targets.

| Target                          | Purpose                                         |
| ------------------------------- | ----------------------------------------------- |
| `make sign-as-task-creator`     | Attest authorship of the task (run after setup) |
| `make sign-as-base-facilitator` | Attest Base team facilitation                   |
| `make sign-as-sc-facilitator`   | Attest Security Council facilitation            |

For active EVM tasks, the signed payload is `config/<network>` and signatures
are written outside it to `signatures/<network>`. A validation file may set
`skipTaskOriginValidation: true` when task-origin validation is not required.
