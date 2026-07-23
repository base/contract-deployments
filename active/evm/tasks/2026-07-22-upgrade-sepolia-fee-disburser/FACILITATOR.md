# Facilitator Guide

Guide for the Base Sepolia `FeeDisburser` upgrade.

## 1. Deploy `FeeDisburser`

```bash
cd contract-deployments/active/evm
TASK_ID=2026-07-22-upgrade-sepolia-fee-disburser TASK_NETWORK=sepolia make deps
TASK_ID=2026-07-22-upgrade-sepolia-fee-disburser TASK_NETWORK=sepolia make deploy-fee-disburser
```

Set `FEE_DISBURSER_IMPL_ADDR` in `config/sepolia/.env` to the deployed implementation.

The initial L2 refund configuration is intentionally empty.

## 2. Generate the validation file

```bash
TASK_ID=2026-07-22-upgrade-sepolia-fee-disburser TASK_NETWORK=sepolia make gen-validation-fee-disburser
```

This produces:

```text
tasks/2026-07-22-upgrade-sepolia-fee-disburser/config/sepolia/validations/base-signer.json
```

Set `"skipTaskOriginValidation": true` in the generated validation file.

## 3. Collect and execute signatures

Ask signers to run `make sign-task` from the repository root and select **Upgrade Sepolia FeeDisburser**.

After collecting the Safe signatures:

```bash
SIGNATURES=AAABBBCCC TASK_ID=2026-07-22-upgrade-sepolia-fee-disburser TASK_NETWORK=sepolia make execute-fee-disburser
```

## 4. Verify

On Base Sepolia, verify:

- `FeeDisburser.version()` returns `1.1.0`.
- `FeeDisburser.L1_WALLET()` returns `0x8D1b5e5614300F5c7ADA01fFA4ccF8F1752D9A57`.
- The proxy implementation is the newly deployed implementation.
- `systemAddresses` and `targetBalances` remain empty.

Then update the README status to `EXECUTED` with the relevant transaction links.
