This is a repo of onchain operational tasks. Pending one-off EVM operations live under `active/evm/tasks/`. Pre-reviewed reusable operations live under dateless `standby/evm/tasks/<operation>/`. Both can hold network invocations under `config/<network>/`. Dated `archive/evm/` tasks are historical.

Standby EVM task lifecycle:

- Canonical standby files contain no real network config, addresses, validations, signatures, execution records, or status file. Scaffold an invocation from the repository root with `make new-task STANDBY_OP=<operation> TASK_NETWORK=<network>`, adding only `config/<network>/.env`, a concise signer README with `Status: READY TO SIGN`, and task-root `status.json`. Generate invocation artifacts there; keep Forge records task-scoped under `records/`.
- Run directly from standby. Do not copy the operation into active or modify its canonical Makefile, Solidity, or root `FACILITATOR.md` for an incident. Every standby Make command requires command-line `TASK_NETWORK=<network>`, even for one network; exported values and defaults are forbidden.
- Keep task-root `status.json` current as the invocation progresses, including signature counts and final execution or cancellation. Never put status under `config/<network>/`, which task-origin signing covers. Finalize status and the signer README together; run `make check-task-status` from the repository root. Archival snapshots status and removes it from standby.
- Re-review canonical code when the target ABI, ownership or responder role, base/contracts pin, or signing workflow changes. Pre-review does not replace incident-specific state and transaction validation.
- Archive only when every present network invocation is executed or canceled and all final artifacts are committed. Use `make TASK_NETWORK=<network> archive-task TASK_DATE=<YYYY-MM-DD>` after fetching main. This snapshots all networks and task-scoped records into a dated, self-contained archive and removes only invocation files from standby.
- Keep the operational PR unmerged until all intended invocations are executed or canceled and the dated archive, final artifacts, and standby invocation removals are committed. On `main`, canonical standby must remain unchanged and contain no invocation-specific data before and after merge.
- Archival must refuse invalid identifiers, overwrite attempts, pending networks, and canonical differences from `origin/main`. Leave canonical standby files byte-for-byte identical. A later invocation starts from the same standby directory, never from an archive.

Active EVM task lifecycle:

- A task directory represents one logical operation and carries its shared Makefile, scripts, and facilitator guide across network rollouts. Add another `config/<network>/` to the existing task instead of creating a duplicate task solely to change networks.
- Scaffold from the repository root with `make new-task TASK_SLUG=<slug> TASK_NETWORK=<network> [TASK_DATE=YYYY-MM-DD]`, or add a network with `make new-task TASK_ID=<task-id> TASK_NETWORK=<network>`. These commands require command-line `TASK_NETWORK` and refuse overwrites.
- Keep task-root `status.json` current as each network progresses, including signature counts and final execution or cancellation. Never put status under `config/<network>/`, which task-origin signing covers. Finalize status and the signer README together; run `make check-task-status` from the repository root.
- A task with multiple network configurations must require `TASK_NETWORK` on each `make` command line. Do not set a mutable default or rely on an exported environment value; use `make TASK_NETWORK=<network> <target>` so the selected network is visible at every invocation.
- Keep the task-root `FACILITATOR.md` authoritative and network-agnostic, using explicit placeholders such as `TASK_NETWORK=<network>` and paths under `config/<network>/`. Per-network facilitator files are discouraged because they duplicate configuration and drift from the shared procedure. Only consider one as a last resort when a network has a materially different procedure that cannot be expressed in the root guide, `.env`, or signer README. If unavoidable, place only the procedural delta in `config/<network>/FACILITATOR.md` and link to it from the root guide.
- Keep a task under `active/evm/tasks/` while any currently intended network rollout remains pending. Do not run `make archive-task` between network rollouts; archive only after every intended network configuration is executed or canceled and its final artifacts are committed.
- Treat `archive/evm/` as historical. Do not edit or execute an archived task in place. For another one-off network rollout, restore the entire active task directory before adding that network. For a standby operation, add a new invocation to its canonical standby directory instead.
- Store network-specific deployment address artifacts such as `addresses.json` under `config/<network>/`. Keep Forge broadcast records at task scope under `records/`; Foundry separates them by script and chain ID.

Task writing:

- Use exact solidity pragma versions based on the contracts used by the task
  - Good: `pragma solidity 0.8.15`
  - Bad: `pragma solidity ^0.8.20`
- Always write "onchain" as one word
- Config values loaded from a `.env` should be stored as immutable variables in the solidity script(s)
- We only need task origin validation for mainnet scripts that go through proxy admin owner
- Do not add `RECORD_STATE_DIFF` to task `.env` files; the signer tool injects `RECORD_STATE_DIFF=true` when it runs Forge
- Include a `FACILITATOR.md` file directed to the task facilitator (explains generating validation file, executing approvals + executing the task)
- Always name the validation file(s) something simple like `base-signer.json` or `security-council-signer.json`. This results in human readable names in the signer tool
  - Do not attempt generating the validation file yourself - the engineer finalizing the task can do this
- The starting README status should be `READY TO SIGN`
- The README file is aimed at signers and should be as simple and concise as possible. Just enough information for signers to sign the task
