# Task Origin Signing

Task origin signatures prove who created and facilitated the task. They are stored with each network config under `active/evm/tasks/<task-id>/config/<network>/signatures/`.

Run these commands only after the network config is final. The signatures cover `active/evm/tasks/<task-id>/config/<network>`, excluding the `signatures/` directory itself, so any change to `.env`, `network.env`, or validation files after this step requires regenerating them.

Mainnet is the production network config. Sepolia and zeronet configs in this branch are copied from mainnet for signer-tool layout demonstration only.

## Task Creator

```bash
cd active/evm
make deps
TASK_ID=2026-06-18-beryl-1 make sign-as-task-creator
```

For a non-default task or network, pass `TASK_ID` and `TASK_NETWORK`:

```bash
TASK_ID=2026-06-18-beryl-2 TASK_NETWORK=sepolia make sign-as-task-creator
```

## Base Facilitator

```bash
cd active/evm
make deps
TASK_ID=2026-06-18-beryl-1 make sign-as-base-facilitator
```

## Security Council Facilitator

```bash
cd active/evm
make deps
TASK_ID=2026-06-18-beryl-1 make sign-as-sc-facilitator
```
