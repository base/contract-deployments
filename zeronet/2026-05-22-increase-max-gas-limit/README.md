# Upgrade SystemConfig to Increase Maximum Gas Limit

Status: EXECUTED

[Deploy SystemConfig impl](https://hoodi.etherscan.io/tx/0xc619806dad6b6a7b1c88135ac82a4d4dd31c8bee00cf6abc8a4d38ca500ebe61) ([artifact](./records/DeploySystemConfig.s.sol/560048/run-1779471994.json))
[Execution](https://hoodi.etherscan.io/tx/0x935dcdf277424427d4b3b2ea42d7de602a21a2ed4eec38c736424020b3e91312) ([artifact](./records/UpgradeSystemConfig.s.sol/560048/run-1779719011.json))

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
