![Base](logo.png)

# contract-deployments

This repo contains execution code and artifacts related to Base contract deployments, upgrades, and calls. For actual contract implementations, see [base-org/contracts](https://github.com/base-org/contracts).

This repo is structured with each network having a high-level directory which contains subdirectories of any "tasks" (contract deployments/calls) that have happened for that network.

## Badges

[![GitHub contributors](https://img.shields.io/github/contributors/base-org/contract-deployments)](https://github.com/base/contract-deployments/graphs/contributors) [![GitHub commit activity](https://img.shields.io/github/commit-activity/w/base-org/contract-deployments)](https://github.com/base/contract-deployments/graphs/contributors) [![GitHub Stars](https://img.shields.io/github/stars/base-org/contract-deployments.svg)](https://github.com/base/contract-deployments/stargazers) ![GitHub repo size](https://img.shields.io/github/repo-size/base/contract-deployments) [![GitHub](https://img.shields.io/github/license/base-org/contract-deployments?color=blue)](https://github.com/base/contract-deployments/blob/main/LICENSE) [![Website base.org](https://img.shields.io/website-up-down-green-red/https/base.org.svg)](https://base.org) [![Blog](https://img.shields.io/badge/blog-up-green)](https://base.mirror.xyz/) [![Docs](https://img.shields.io/badge/docs-up-green)](https://docs.base.org/) [![Discord](https://img.shields.io/discord/1067165013397213286?label=discord)](https://base.org/discord) [![Twitter BuildOnBase](https://img.shields.io/twitter/follow/BuildOnBase?style=social)](https://x.com/BuildOnBase) [![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/base-org/contract-deployments)](https://github.com/base/contract-deployments/pulls) [![GitHub Issues](https://img.shields.io/github/issues-raw/base-org/contract-deployments.svg)](https://github.com/base/contract-deployments/issues) ![Build Status](https://img.shields.io/github/actions/workflow/status/base-org/contract-deployments/ci.yml) ![Tests](https://img.shields.io/badge/tests-passing-brightgreen) ![Checks](https://img.shields.io/badge/checks-passing-brightgreen)

## Documentation

- [API Documentation](API.md)
- [Audit S3 Format](AUDIT_S3_FORMAT.md)
- [Bundle States](BUNDLE_STATES.md)
- [Signer Guide](SIGNER.md)

## Setup

First, install forge if you don't have it already:

- Run `make install-foundry` to install [`Foundry`](https://github.com/foundry-rs/foundry/commit/3b1129b5bc43ba22a9bcf4e4323c5a9df0023140).

## Task Execution

To execute a new task, run one of the following commands (depending on the type of change you're making):

### Generic Tasks
```bash
make setup-task network=<network> task=<task-name>
```

### Gas Increase Tasks
```bash
make setup-gas-increase network=<network>
```

### Funding Tasks
```bash
make setup-funding network=<network>
```

### Fault Proof Upgrade
```bash
make setup-upgrade-fault-proofs network=<network>
```

### Safe Management Tasks
```bash
make setup-safe-management network=<network>
```

### Bridge Partner Threshold
```bash
make setup-bridge-partner-threshold network=<network>
```

### Bridge Pause/Unpause
```bash
make setup-bridge-pause network=<network>
```

## Next Steps

Next, `cd` into the directory that was created for you and follow the steps listed below for the relevant template.

> **👥 For Signers:** Please read the [Signer Guide](SIGNER.md) for step-by-step instructions on using the validation UI.

## Validation Files

Please note, you will need to manually create validation file(s) for your task as they are bespoke to each task and therefore not created automatically as a part of the templates. We use one validation Markdown file per multisig involved in the task:

- Single multisig: Create a `VALIDATION.md` file at the root of your task
- Multiple multisigs: Create a `validations/` subdirectory at the root of your task containing the corresponding validation Markdown files

If you need examples to work from, you can browse through similar past tasks in this repo and adapt them to your specific task. Also, please note that we have tooling to generate these files (like the `task-signer-tool`) which removes the manual aspect of creating these validation files.
