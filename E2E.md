# test/e2e branch

Long-lived branch for end-to-end testing of the [task signing tool](https://github.com/base/task-signing-tool).
It is never merged into `main`. Test tasks here are `READY TO SIGN` on purpose and would confuse real signers on
`main`.

## Contents

- `active/evm/tasks/2026-10-17-e2e-bump-safe-nonce/`: Zeronet test task in the same shape as a real task. The
  Zeronet Base multisig calls its own `nonce()`, so the only state change is the Safe nonce increment. Profile:
  `base-signer.json`.
- `scripts/apply-signer-standby.sh`: also accepts signing-tool commits other than the reviewed pin, so unreleased tool
  changes can be tested.

## Test a signing-tool commit

```bash
make sign-task SIGNER_TOOL_COMMIT=<commit>
```

Pick "E2E Test: Bump Safe Nonce" (Zeronet), then "Base Signer".

Trezor signing needs the full SafeTx in `stateDiff.json`. base/contracts `MultisigScript.sign` does not record it
yet, so the task simulates through `signWithSafeTx`, which calls `sign` and then adds `safeTx` itself. Trezor also
needs `trezorctl` (`pipx install trezor`) and a Core-firmware device: Model T, Safe 3 or Safe 5.

## Rules

- Sign only. Do not send signatures anywhere. Executing bumps the Zeronet Base multisig nonce and invalidates
  signatures for other pending Zeronet tasks.
- The Safe nonce is part of the signed hash. After any Base multisig transaction on Zeronet, or after merging `main`
  when pins or `config/*.env` change, run `make TASK_NETWORK=zeronet gen-validation-cb` in the task directory and
  commit the result.
