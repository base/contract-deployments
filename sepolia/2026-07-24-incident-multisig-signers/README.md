# Update Sepolia Incident Multisig Signers

Status: READY TO SIGN

## Description

This task updates the owner sets for the Sepolia Incident Multisig and mock Security Council Safe.

It replaces `0x72069542Ca378553A3D479c82Adc31f21CA6dE4a` with `0x2c1475476B586d66a85bC65A5aB396BBbAa4f3aD` on both Safes. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

## Procedure

1. Run `make sign-task` from `contract-deployments`.
2. Open [http://localhost:3000](http://localhost:3000) and select `sepolia/2026-07-24-incident-multisig-signers`.
3. Select `base-signer.json` for the Incident Multisig or `security-council-signer.json` for the mock Security Council Safe, then sign the task.
4. Send the signature to the facilitator.

See `FACILITATOR.md` for execution instructions.
