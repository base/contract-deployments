# Session Handoff

## Current Goal

Contract Ops Reorg is staged on branch `feat/reorg-contracts-ops`.

The branch moves contract-deployment operations to the active/archive layout, keeps signer UI behavior intact, and moves reusable EVM scripts into categorized `active/evm/script/common/` folders.

## Pushed Commits

`base/task-signing-tool`, branch `feat-reorg-contracts-ops`:
- `5461faa feat: support per-network task signatures`

`base/contract-deployments`, branch `feat/reorg-contracts-ops`:
- `f52edc1 chore: archive legacy task history`
- `21d24fd feat: add active evm task layout`
- `f4e9a78 archive solana folder into correct location`
- `4c26e9e docs: document active evm network config layout`
- `b7fb1ea refactor: move reusable evm scripts to common`

## Current Layout

- Legacy history lives under `archive/legacy/`.
- Current EVM work lives under `active/evm`.
- Network config lives under `active/evm/config/<network>/`.
- Validation files live under `active/evm/config/<network>/validations/`.
- Task-origin signatures live under `active/evm/config/<network>/signatures/`.
- Task-origin signatures cover `active/evm/config/<network>` and the signer tool excludes nested `signatures/`.
- Mainnet is the real Beryl task. Sepolia and zeronet are copied demo configs for signer-tool layout testing and have `skipTaskOriginValidation=true`.

## Common Scripts

Reusable EVM scripts now live under categorized folders:

- `active/evm/script/common/verifier-update/DeployAggregateVerifier.s.sol`
- `active/evm/script/common/verifier-update/UpdateVerifierHashes.s.sol`
- `active/evm/script/common/funding/Fund.s.sol`
- `active/evm/script/common/gas/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol`
- `active/evm/script/common/bridge/PauseBridge.s.sol`
- `active/evm/script/common/bridge/SetThreshold.s.sol`
- `active/evm/script/common/superchain/PauseSuperchainConfig.s.sol`
- `active/evm/script/common/safe/UpdateSigners.s.sol`

Use `active/evm/script/common/README.md` as the policy: if a script is expected to be used regularly, put it in `common/<category>/`; keep one-off task scripts outside `common/`.

Do not change exact Solidity pragma versions when moving scripts. `SetThreshold.s.sol` remains `pragma solidity 0.8.28`; most other common scripts remain `pragma solidity 0.8.15`.

## Deleted Legacy Template Surface

- Deleted `setup-templates/`.
- Removed root Makefile `setup-*` copy targets that depended on `setup-templates/`.
- Deleted `.github/workflows/validate-templates.yml`.
- Updated README wording so it no longer advertises setup-template commands.

## Signer Tool Behavior

Root `Makefile` pins:
- `SIGNER_TOOL_COMMIT=5461faaacba3d7b0dfc942e9a1ed631e1be84621`

The signer tool discovers active tasks from `active/evm/config/<network>/validations/`, reads task display metadata from `active/evm/config/<network>/README.md` or `active/evm/README.md`, and validates task-origin signatures from `active/evm/config/<network>/signatures/`.

## Verification Already Run

- `forge fmt --check active/evm/script/common`
- `git diff --check`
- JSON parse check for all validation files under `active/evm/config/*/validations/*.json`
- `make -C active/evm -n deploy-aggregate-verifier VERIFIER_API_KEY=dummy`
- `make -C active/evm -n gen-validation-update-verifier-hashes-cb`
- `make -C active/evm -n TASK_NETWORK=zeronet sign-as-task-creator`
- `make -C active/evm deps`
- `forge build` from `active/evm`, compiling exact compiler sets `0.8.15` and `0.8.28`
- task-signing-tool tests:
  - `npm test -- __tests__/task-origin-validate.test.ts`
  - `npm test -- __tests__/genTaskOriginSig.test.ts`
  - `npm run format:check -- ...`

## Current Working Tree Notes

- `AGENTS.md` contains this handoff update.
- `task-signing-tool/` is an untracked nested checkout used locally; do not add it to the outer `contract-deployments` repo.
- The outer repo branch is otherwise pushed through `b7fb1ea`.

## Suggested Next Steps

1. Review `b7fb1ea` for common-script category layout and setup-template removal.
2. Continue Phase 4 archival tooling for moving completed `active/evm` tasks into `archive/`.


MAIN (DONT CHANGE)
This is a repo of onchain operational tasks. Each network has its own directory with each individual task as a sub-directory.

Task writing:

- Use exact solidity pragma versions based on the contracts used by the task
  - Good: `pragma solidity 0.8.15`
  - Bad: `pragma solidity ^0.8.20`
- Always use "onchain" instead of "on-chain"
- Config values loaded from a `.env` should be stored as immutable variables in the solidity script(s)
- We only need task origin validation for mainnet scripts that go through proxy admin owner
- `RECORD_STATE_DIFF=true` is needed in the task `.env` file in order for the signer tool to work
- Include a `FACILITATOR.md` file directed to the task facilitator (explains generating validation file, executing approvals + executing the task)
- Always name the validation file(s) something simple like `base-signer.json` or `security-council-signer.json`. This results in human readable names in the signer tool
  - Do not attempt generating the validation file yourself - the engineer finalizing the task can do this
- The starting README status should be `READY TO SIGN`
- The README file is aimed at signers and should be as simple and concise as possible. Just enough information for signers to sign the task
