# Update Sepolia Incident Multisig Signers

Status: EXECUTED ([Incident Multisig](https://sepolia.etherscan.io/tx/0x67f0110015d7854276b90bb8e3915b44d6aba2022b06d1994454d101dc3dd6b3) and [mock Security Council Safe](https://sepolia.etherscan.io/tx/0x0e33d244f0c2ebf1c938eb67e746fc02a91652621ae48b32f41be95b721bd11c))

## Transactions

- Incident Multisig update ([`0x646132A1667ca7aD00d36616AFBA1A28116C770A`](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A)): [`0x67f0110015d7854276b90bb8e3915b44d6aba2022b06d1994454d101dc3dd6b3`](https://sepolia.etherscan.io/tx/0x67f0110015d7854276b90bb8e3915b44d6aba2022b06d1994454d101dc3dd6b3) (artefacts: [run-1784930653795.json](./records/UpdateSigners.s.sol/11155111/run-1784930653795.json))
- Mock Security Council Safe update ([`0x6AF0674791925f767060Dd52f7fB20984E8639d8`](https://sepolia.etherscan.io/address/0x6AF0674791925f767060Dd52f7fB20984E8639d8)): [`0x0e33d244f0c2ebf1c938eb67e746fc02a91652621ae48b32f41be95b721bd11c`](https://sepolia.etherscan.io/tx/0x0e33d244f0c2ebf1c938eb67e746fc02a91652621ae48b32f41be95b721bd11c) (artefacts: [run-1784930880560.json](./records/UpdateSigners.s.sol/11155111/run-1784930880560.json))

## Description

This task updates the owner sets for the Sepolia Incident Multisig and mock Security Council Safe.

It replaces `0x72069542Ca378553A3D479c82Adc31f21CA6dE4a` with `0x2c1475476B586d66a85bC65A5aB396BBbAa4f3aD` on both Safes. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

## Procedure

1. Run `make sign-task` from `contract-deployments`.
2. Open [http://localhost:3000](http://localhost:3000) and select `sepolia/2026-07-24-incident-multisig-signers`.
3. Select `base-signer.json` for the Incident Multisig or `security-council-signer.json` for the mock Security Council Safe, then sign the task.
4. Send the signature to the facilitator.

See `FACILITATOR.md` for execution instructions.
