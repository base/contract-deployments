# Facilitator Guide

Guide for facilitators managing the mainnet `FeeDisburser` owner transfer.

## 1. Generate the validation file

Run this after any change to [.env](./.env) or [script/TransferFeeDisburserOwnership.s.sol](./script/TransferFeeDisburserOwnership.s.sol).

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-12-transfer-feedisburser-owner-l1alias
make deps
make gen-validation
```

This produces `validations/base-signer.json`. Check that the `cmd` field uses:

```text
--sender 0x6CD3850756b7894774Ab715D136F9dD02837De50
```

Mainnet validation files must not contain `skipTaskOriginValidation`.

## 2. Task origin signing

Run these only after `.env`, the script, and the validation file are final. The signatures cover the whole task folder, so any later change requires regenerating them. Signatures are stored in `mainnet/signatures/2026-06-12-transfer-feedisburser-owner-l1alias/`.

### Task creator

```bash
make sign-as-task-creator
```

### Base facilitator

```bash
make sign-as-base-facilitator
```

### Security Council facilitator

```bash
make sign-as-sc-facilitator
```

## 3. Collect signatures

Ask signers to follow [README.md](./README.md). They should run `make sign-task` from the repo root and select `mainnet/2026-06-12-transfer-feedisburser-owner-l1alias` in the signing UI.

## 4. Execute

This task uses direct signatures from `OWNER_SAFE`, so there are no separate nested Safe approval transactions. Concatenate the collected signatures and pass them to `make execute`.

After collecting enough signatures:

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-12-transfer-feedisburser-owner-l1alias
make deps
SIGNATURES=AAABBBCCC make execute
```

Replace `AAABBBCCC` with the concatenated signatures collected from signers.

After execution, verify on Base mainnet that `FeeDisburser.admin()` returns `0xa966054731540a48b28990b63Dcf4f33d8aE57B2`:

```bash
cast call 0x09C7bAD99688a55a2e83644BFAed09e62bDcCcBA \
  "admin()(address)" \
  --from 0xa966054731540a48b28990b63Dcf4f33d8aE57B2 \
  --rpc-url https://mainnet.base.org
```

Then update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any generated execution records.
