```md
# Task execution checklist
```
This checklist is for running a new deployment/call “task” safely and consistently.

## Before you start

- Confirm which network you are targeting (e.g. `mainnet`, `sepolia`, `sepolia-alpha`).
- Make sure Foundry is installed (or run the repo’s install helper).
- Verify you have access to the correct signer / Safe.

## Create a new task directory

- Create the task folder under the appropriate network directory.
- Keep naming consistent and descriptive (e.g. `2026-01-09_upgrade_xyz`).

## Dry run locally

- Run formatting / linting if applicable.
- Run a dry-run / simulation against the intended RPC endpoint.
- Double-check addresses and calldata.

## Review items

- Output artifacts are committed (if the repo requires them).
- Human-readable explanation is included (README in the task folder is ideal).
- No secrets are committed (private keys, mnemonics, RPC keys).

## After execution

- Record final tx hashes and resulting deployed addresses.
- Add a short “Result” section in the task README.
- Link to block explorer and Safe transaction where relevant.
