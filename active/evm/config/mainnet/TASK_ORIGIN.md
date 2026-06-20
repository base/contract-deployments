# Task Origin Signing

Task origin signatures prove who created and facilitated the task. They are stored in `active/evm/config/signatures/mainnet/`.

Run these commands only after `active/evm/config/mainnet` is final. The signatures cover `active/evm/config/mainnet`, so any change to config, signer docs, or validation files after this step requires regenerating them.

## Task Creator

```bash
cd active/evm
make deps
make sign-as-task-creator
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
