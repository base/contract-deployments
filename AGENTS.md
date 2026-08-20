This is a repo of onchain operational tasks. Active EVM tasks live under `active/evm/tasks/`; one task directory may contain configurations for multiple networks under `config/<network>/`.

Active EVM task lifecycle:

- A task directory represents one logical operation and carries its shared Makefile, scripts, and facilitator guide across network rollouts. Add another `config/<network>/` to the existing task instead of creating a duplicate task solely to change networks.
- A task with multiple network configurations must require `TASK_NETWORK` on each `make` command line. Do not set a mutable default or rely on an exported environment value; use `make TASK_NETWORK=<network> <target>` so the selected network is visible at every invocation.
- Keep the task-root `FACILITATOR.md` authoritative and network-agnostic, using explicit placeholders such as `TASK_NETWORK=<network>` and paths under `config/<network>/`. Per-network facilitator files are discouraged because they duplicate configuration and drift from the shared procedure. Only consider one as a last resort when a network has a materially different procedure that cannot be expressed in the root guide, `.env`, or signer README. If unavoidable, place only the procedural delta in `config/<network>/FACILITATOR.md` and link to it from the root guide.
- Keep a task under `active/evm/tasks/` while any currently intended network rollout remains pending. Do not run `make archive-task` between network rollouts; archive only after every intended network configuration is executed or canceled and its final artifacts are committed.
- Treat `archive/evm/` as historical. Do not edit or execute an archived task in place. If the same operation later needs another network rollout, restore the entire task directory to `active/evm/tasks/` before adding that network.
- Store network-specific deployment address artifacts such as `addresses.json` under `config/<network>/`. Keep Forge broadcast records at task scope under `records/`; Foundry separates them by script and chain ID.

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
