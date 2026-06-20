# Facilitator Guide

Guide for facilitators managing the mainnet `BalanceTracker` system-address upgrade.

## 1. Deploy the new implementation

The multisig call points the proxy at a freshly deployed `BalanceTracker` implementation, so it must be deployed first (EOA-authorized phase, with a Ledger). The implementation reuses the profit wallet read straight from the live proxy, so there is nothing to configure for it.

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-09-upgrade-balance-tracker
make deps
make deploy-balance-tracker
```

`make deploy-balance-tracker` runs `DeployBalanceTracker`:

- reads `PROFIT_WALLET` from the live proxy and deploys the implementation with it
- writes `balanceTrackerImplementation` to [addresses.json](./addresses.json)

Commit the updated `addresses.json`; `UpgradeBalanceTracker` reads the implementation from there.

## 2. Generate the validation file

Run this after `addresses.json` is set and after any change to [.env](./.env) or [script/UpgradeBalanceTracker.s.sol](./script/UpgradeBalanceTracker.s.sol).

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-09-upgrade-balance-tracker
make deps
make gen-validation
```

This produces `validations/base-signer.json`. Check that the `cmd` field uses:

```text
--sender 0x1841CB3C2ce6870D0417844C817849da64E6e937
```

Mainnet validation files must not contain `skipTaskOriginValidation`.

## 3. Task origin signing

Run these only after `.env`, `addresses.json`, and the validation file are final — the signatures cover the whole task folder, so any later change requires regenerating them. Signatures are stored in `mainnet/signatures/2026-06-09-upgrade-balance-tracker/`.

### Task creator:
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

## 4. Collect signatures

Ask signers to follow [README.md](./README.md). They should run `make sign-task` from the repo root and select `mainnet/2026-06-09-upgrade-balance-tracker` in the signing UI.

## 5. Execute

After collecting enough signatures:

```bash
cd contract-deployments
git pull
cd mainnet/2026-06-09-upgrade-balance-tracker
make deps
SIGNATURES=AAABBBCCC make execute
```

Replace `AAABBBCCC` with the concatenated signatures collected from signers.

After execution, update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any generated execution records.
