# Task Origin Signing

Task origin signatures prove who created and facilitated the task. They are stored in `mainnet/signatures/2026-04-28-activate-multiproof/`.

Run these commands only after the task folder is final. The signatures cover the task folder, so any change to `.env`, `addresses.json`, scripts, docs, or validation files after this step requires regenerating them.

## Task Creator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-task-creator
```

## Base Facilitator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-base-facilitator
```

## Security Council Facilitator

```bash
cd contract-deployments/mainnet/2026-04-28-activate-multiproof
make sign-as-sc-facilitator
```
