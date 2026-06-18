# Task Origin Signing

Task origin signatures prove who created and facilitated the task. They are stored in `mainnet/signatures/2026-06-12-beryl/`.

Run these commands only after the task folder is final. The signatures cover the task folder, so any change to `.env`, `addresses.json`, scripts, docs, or validation files after this step requires regenerating them.

## Task Creator

```bash
cd mainnet/2026-06-12-beryl
make deps
make sign-as-task-creator
```

## Base Facilitator

```bash
cd mainnet/2026-06-12-beryl
make deps
make sign-as-base-facilitator
```

## Security Council Facilitator

```bash
cd mainnet/2026-06-12-beryl
make deps
make sign-as-sc-facilitator
```
