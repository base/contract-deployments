# Upgrade SystemConfig to Increase Maximum Gas Limit

Status: READY TO SIGN

## Description

This task upgrades the SystemConfig implementation on Sepolia to increase `MAX_GAS_LIMIT` from 500,000,000 (500M) to 2,000,000,000 (2B).

This is a prerequisite for the gas limit + elasticity increase task (`sepolia/2026-05-06-increase-gas-and-elasticity-limit`), which sets the operational gas limit to 1,200,000,000 (1.2B). The current `MAX_GAS_LIMIT` of 500M would reject that value.

The new max of 2B provides headroom for future gas limit increases beyond 1.2B.

This task contains two scripts:
1. `DeploySystemConfigScript` -- Deploys a new SystemConfig implementation with the patched `MAX_GAS_LIMIT`. This is run by the facilitator before signing.
2. `UpgradeSystemConfigScript` -- Upgrades the SystemConfig proxy to point to the new implementation via the ProxyAdmin owner Safe.

No storage changes occur since only the `MAX_GAS_LIMIT` constant and `version()` string are modified.

**NOTE:** Signers should not need to run the `DeploySystemConfigScript` script as it will be run beforehand by the facilitator. The rest of this document focuses on using the `UpgradeSystemConfigScript` script.

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2026-05-06-increase-max-gas-limit
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum application needs to be opened on Ledger with the message "Application is ready".

### 3. Simulate, Validate, and Sign

Make sure your ledger is still unlocked and run the appropriate command:

For OP signers:
```bash
make sign-op
```

For Base signers:
```bash
make sign-base
```

You will see a "Simulation link" from the output. Paste this URL in your browser to validate the state diff.

Validate:
1. Network is `Sepolia`
2. Timestamp is recent
3. The only state change is the SystemConfig proxy implementation slot being updated to the new implementation address

### 4. Send signature to facilitator

Share the `Data`, `Signer` and `Signature` with the facilitator.
