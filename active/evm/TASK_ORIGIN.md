# Task Origin Signing

Task origin signatures prove who created and facilitated the task. They are stored with each network config under `active/evm/config/<network>/signatures/`.

Run these commands only after the network config is final. The signatures cover `active/evm/config/<network>`, excluding the `signatures/` directory itself, so any change to `.env`, `network.env`, or validation files after this step requires regenerating them.

Mainnet is the production task. Sepolia and zeronet configs in this branch are copied from mainnet for signer-tool layout demonstration only.

## Task Creator

```bash
cd active/evm
make deps
make sign-as-task-creator
```

For a non-default network, pass `TASK_NETWORK`:

```bash
TASK_NETWORK=sepolia make sign-as-task-creator
```

## Base Facilitator

```bash
cd active/evm
make deps
make sign-as-base-facilitator
```

## Security Council Facilitator

```bash
cd active/evm
make deps
make sign-as-sc-facilitator
```
