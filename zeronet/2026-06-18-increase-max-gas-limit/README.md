# Upgrade SystemConfig to Increase Maximum Gas Limit

Status: PREPARED (regenesis 2026-06-18, Phase B+ step 1) — run AFTER the fresh L1 deploy, BEFORE increase-gas-and-elasticity. Patches stock SystemConfig MAX_GAS_LIMIT 500M→2B. Cloned from 2026-05-22-increase-max-gas-limit; needs new SYSTEM_CONFIG/L1_PROXY_ADMIN.

[Deploy SystemConfig impl](https://hoodi.etherscan.io/tx/0xc619806dad6b6a7b1c88135ac82a4d4dd31c8bee00cf6abc8a4d38ca500ebe61) ([artifact](./records/DeploySystemConfig.s.sol/560048/run-1779471994.json))
[CB approval](https://hoodi.etherscan.io/tx/0x315b0791412f2e88d4c9c9a416f6e3c6517da40a9877c040a23ed993d656d3ed) ([artifact](./records/UpgradeSystemConfig.s.sol/560048/run-1779717772.json))
[SC approval](https://hoodi.etherscan.io/tx/0x935dcdf277424427d4b3b2ea42d7de602a21a2ed4eec38c736424020b3e91312) ([artifact](./records/UpgradeSystemConfig.s.sol/560048/run-1779719011.json))
[Execution](https://hoodi.etherscan.io/tx/0xc4e9606618cb2ca302f2c7efa1adc6fd7e3ae708817774fcb0480d626b830a88) ([artifact](./records/UpgradeSystemConfig.s.sol/560048/run-1779719150.json))

## Description

This task upgrades the SystemConfig implementation on Zeronet to increase `MAX_GAS_LIMIT` from 500,000,000 (500M) to 2,000,000,000 (2B).

The new max of 2B provides headroom for future gas limit increases.

This task contains two scripts:
1. `DeploySystemConfigScript` -- Deploys a new SystemConfig implementation with the patched `MAX_GAS_LIMIT`. This is run by the facilitator before signing.
2. `UpgradeSystemConfigScript` -- Upgrades the SystemConfig proxy to point to the new implementation via the ProxyAdmin owner Safe.

No storage changes occur since only the `MAX_GAS_LIMIT` constant and `version()` string are modified.

**NOTE:** Signers should not need to run the `DeploySystemConfigScript` script as it will be run beforehand by the facilitator. The rest of this document focuses on using the `UpgradeSystemConfigScript` script.

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run signing tool

```bash
cd contract-deployments
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
