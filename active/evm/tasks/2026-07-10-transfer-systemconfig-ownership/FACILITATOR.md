# Facilitator Guide

Guide for facilitators managing the Zeronet `SystemConfig` owner transfer.

## 1. Generate validation files

Run this after any change to the task config or script:

```bash
cd contract-deployments/active/evm
make deps
make gen-validation-cb
make gen-validation-sc
```

This produces:

- `tasks/2026-07-10-transfer-systemconfig-ownership/config/zeronet/validations/base-signer.json`
- `tasks/2026-07-10-transfer-systemconfig-ownership/config/zeronet/validations/security-council-signer.json`

Check that both `cmd` fields use:

```text
--sender 0x821Ff2A3fB66B008fA668B40Eca9d3535B246575
```

Because this is a Zeronet task, set this field at the JSON root in both validation files:

```json
"skipTaskOriginValidation": true
```

## 2. Collect signatures

Ask signers to run `make sign-task` from the repository root and select **Transfer Zeronet `SystemConfig` Owner**.

## 3. Approve and execute

From `active/evm`, execute the Coinbase and Security Council approvals:

```bash
SIGNATURES=AAABBBCCC make approve-cb
SIGNATURES=AAABBBCCC make approve-sc
make execute
```

## 4. Verify onchain

```bash
cast call 0x0a111C7980152bDe41D71f48e2E1d8184f5f6187 "owner()(address)" \
  --rpc-url https://c3-chainproxy-eth-hoodi-full-dev.cbhq.net
```

Expected result:

```text
0x856611ed7e07d83243b15e93f6321f2df6865852
```

Then update the task status to `EXECUTED` with the transaction link and commit the execution records.
