# Upgrade SystemConfig to Increase Maximum Gas Limit

Status: EXECUTED

[Deploy SystemConfig impl](https://sepolia.etherscan.io/tx/0x5ba94274a2e711913eb26e981ed533d951fac2cdacf09fe49b42442d3806ea77) ([artifact](./records/DeploySystemConfig.s.sol/11155111/run-1778155955997.json))
[Base approval](https://sepolia.etherscan.io/tx/0x8016fdd7f5fe9bc7b1dea0efda256296d4a3247021d5661eec45a9c3c06675dc)
[OP approval](https://sepolia.etherscan.io/tx/0xa8fd376662c338a95ad5e45b787328f94ea703fa28d272925122a96d9f3a1be6)
[Execution](https://sepolia.etherscan.io/tx/0xfc19dd76b8a0c6fd85fe538a6b1b48c4b6c8fe0d8b5cb795555aa839ab6cbdd0)

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

### Sign Task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run the signing tool

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
