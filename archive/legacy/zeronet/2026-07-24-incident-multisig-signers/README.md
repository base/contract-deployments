# Update Zeronet Incident Multisig Signers

Status: EXECUTED ([Incident Multisig](https://hoodi.etherscan.io/tx/0x4d0dd5df80e19a756506283660445196c3e23e41eac8e97e34dc65d6dde4e1be) and [mock Security Council Safe](https://hoodi.etherscan.io/tx/0x440697b246ae103cf94fca3645f6b578692db2d52deea685a7df76848565668c))

## Transactions

- Incident Multisig update ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0x4d0dd5df80e19a756506283660445196c3e23e41eac8e97e34dc65d6dde4e1be`](https://hoodi.etherscan.io/tx/0x4d0dd5df80e19a756506283660445196c3e23e41eac8e97e34dc65d6dde4e1be) (artefacts: [run-1784926299122.json](./records/UpdateSigners.s.sol/560048/run-1784926299122.json))
- Mock Security Council Safe update ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0x440697b246ae103cf94fca3645f6b578692db2d52deea685a7df76848565668c`](https://hoodi.etherscan.io/tx/0x440697b246ae103cf94fca3645f6b578692db2d52deea685a7df76848565668c) (artefacts: [run-1784926408328.json](./records/UpdateSigners.s.sol/560048/run-1784926408328.json))

## Description

This task updates the owner sets for the Zeronet Incident Multisig and mock Security Council Safe.

It replaces `0x72069542Ca378553A3D479c82Adc31f21CA6dE4a` with `0x2c1475476B586d66a85bC65A5aB396BBbAa4f3aD` on both Safes. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

## Procedure

1. Run `make sign-task` from `contract-deployments`.
2. Open [http://localhost:3000](http://localhost:3000) and select `zeronet/2026-07-24-incident-multisig-signers`.
3. Select `base-signer.json` for the Incident Multisig or `security-council-signer.json` for the mock Security Council Safe, then sign the task.
4. Send the signature to the facilitator.

See `FACILITATOR.md` for execution instructions.
