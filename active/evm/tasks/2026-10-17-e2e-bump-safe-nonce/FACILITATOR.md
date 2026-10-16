# E2E Test: Bump Safe Nonce — Facilitator Guide

This task is a fixture for testing the signing tool end to end. The Base multisig calls its own
`nonce()` view, so the signed transaction does nothing except bump the Safe nonce if executed.

It lives on the `test/e2e` branch only. Never merge it into main: a READY TO SIGN task on main would
show up for real signers.

Replace `<network>` with the test network (`zeronet`). Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory (`active/evm/tasks/2026-10-17-e2e-bump-safe-nonce/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

## 2. Generate the validation file

```bash
make TASK_NETWORK=<network> gen-validation-cb
```

This writes `config/<network>/validations/base-signer.json` with `skipTaskOriginValidation: true`.
The Safe nonce is part of the signed hash, so regenerate and commit the file after any Base multisig
transaction on `<network>`. A stale file fails validation in the signing tool with a hash mismatch.

## 3. Sign

From the repository root:

```bash
make sign-task SIGNER_TOOL_COMMIT=<commit>
```

## 4. Execute (optional)

Only to test the execution path. It bumps the Base multisig nonce, which invalidates signatures for
any other pending task on this Safe.

```bash
SIGNATURES=<concatenated base signatures> make TASK_NETWORK=<network> execute
```

After execution the script checks that the nonce rose by exactly one and that nothing else changed.
Regenerate the validation file afterwards.
