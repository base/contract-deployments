# Facilitator Guide

Guide for the Base mainnet `FeeDisburser` upgrade.

## 1. Deploy `FeeDisburser`

```bash
cd contract-deployments/active/evm
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make deps
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make deploy-fee-disburser
```

Set `FEE_DISBURSER_IMPL_ADDR` in `config/mainnet/.env` to the deployed implementation.

The initial L2 refund configuration is intentionally empty.

## 2. Generate the validation file

```bash
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make gen-validation-fee-disburser
```

This produces:

```text
tasks/2026-07-23-upgrade-mainnet-fee-disburser/config/mainnet/validations/base-signer.json
```

## 3. Generate task-origin signatures

After the task configuration, scripts, and validation file are final, generate the task-origin signatures:

```bash
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make sign-as-task-creator
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make sign-as-base-facilitator
TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make sign-as-sc-facilitator
```

Commit the generated files under:

```text
tasks/2026-07-23-upgrade-mainnet-fee-disburser/signatures/mainnet/
```

## 4. Collect and execute signatures

Ask signers to run `make sign-task` from the repository root and select **Upgrade Mainnet FeeDisburser**.

After collecting the Safe signatures:

```bash
SIGNATURES=AAABBBCCC TASK_ID=2026-07-23-upgrade-mainnet-fee-disburser TASK_NETWORK=mainnet make execute-fee-disburser
```

## 5. Verify

On Base mainnet, verify:

- `FeeDisburser.version()` returns `1.1.0`.
- `FeeDisburser.L1_WALLET()` returns `0x23B597f33f6f2621F77DA117523Dffd634cDf4ea`.
- The proxy implementation is the newly deployed implementation.
- `systemAddresses` and `targetBalances` remain empty.

Then update the README status to `EXECUTED` with the relevant transaction links.
