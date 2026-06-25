# Facilitator Guide

Guide for facilitators managing the mainnet Incident Multisig signer update.

## Task Origin Signing

After setting up the task, generate cryptographic attestations (sigstore bundles) to prove who created and facilitated the task. These signatures are stored in `mainnet/signatures/2026-05-13-incident-multisig-signers/`.

### Task creator (run after task setup):
```bash
make sign-as-task-creator
```

### Base facilitator:
```bash
make sign-as-base-facilitator
```

### Security Council facilitator:
```bash
make sign-as-sc-facilitator
```

## Generate Validation File

Run this after any change to [OwnerDiff.json](./OwnerDiff.json), [.env](./.env), or [script/UpdateSigners.s.sol](./script/UpdateSigners.s.sol).

```bash
cd contract-deployments
git pull
cd mainnet/2026-05-13-incident-multisig-signers
make deps
make gen-validation
```

This produces `validations/base-signer.json`. Check that the `cmd` field uses:

```text
--sender 0x1841CB3C2ce6870D0417844C817849da64E6e937
```

## Collect Signatures

Ask signers to follow [README.md](./README.md). They should run `make sign-task` from the repo root and select `mainnet/2026-05-13-incident-multisig-signers` in the signing UI.

## Execute

After collecting enough signatures:

```bash
cd contract-deployments
git pull
cd mainnet/2026-05-13-incident-multisig-signers
make deps
SIGNATURES=AAABBBCCC make execute
```

Replace `AAABBBCCC` with the concatenated signatures collected from signers.

After execution, update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any generated execution records.
