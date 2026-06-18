# Update Gas Limit, EIP-1559 Params & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: PREPARED (regenesis 2026-06-18, Phase B+ step 2) — run AFTER increase-max-gas-limit. Sets gasLimit 25M→1.2e9, eip1559 →15/100, da scalar →119. Cloned from 2026-05-22-increase-gas-and-elasticity-limit; addresses load from zeronet/.env (must be updated first).

[CB approval](https://hoodi.etherscan.io/tx/0x844ee1ef1070746997ffa17de60848eb8fc57aa37e224121a89361c851ea1fbf) ([artifact](./records/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol/560048/run-1779834710.json))
[SC approval](https://hoodi.etherscan.io/tx/0x38b212c5ca9b79a0d6a97d070e7dd951fe5ed7bc03129637c74c2e3cb7c5e7b0) ([artifact](./records/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol/560048/run-1779834794.json))
[Execution](https://hoodi.etherscan.io/tx/0xfe75645310cea9a8e1ae0bf9e94e6ce197253f1662ea8543345404692be27a84) ([artifact](./records/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol/560048/run-1779834889.json))

## Description

We are updating the gas limit, EIP-1559 elasticity, EIP-1559 denominator, and DA footprint gas
scalar on Zeronet to bring it to parity with the Sepolia configuration set by
`sepolia/2026-05-06-increase-gas-and-elasticity-limit`.

```
current:  gas_limit = 25,000,000,    elasticity = 6  (default) -> gas_target = 4,166,666
proposed: gas_limit = 1,200,000,000, elasticity = 15           -> gas_target = 80,000,000
```

This runbook invokes `IncreaseEip1559ElasticityAndIncreaseGasLimitScript` which allows our signers
to sign the same call with two different sets of parameters:

- **Upgrade**: gas limit → 1,200,000,000, elasticity → 15, denominator → 100, DA footprint gas scalar → 119
- **Rollback**: gas limit → 25,000,000, elasticity → 6, denominator → 250, DA footprint gas scalar → 400

### Note on the rollback values

The L1 `SystemConfig` storage on Zeronet has never had its EIP-1559 params or DA footprint scalar
explicitly written (raw storage is all zeros). The contract's `setEIP1559Params` enforces
`denominator >= 1` and `elasticity >= 1`, so the rollback cannot restore literal zeros. Instead,
the rollback targets the rollup-config defaults the chain actually operates with
(denominator=250, elasticity=6, daFootprintGasScalar=400).

### DA Footprint Gas Scalar

The DA footprint gas scalar is set to 119, computed via the `make da-scalar` helper:

```
da_footprint_gas_scalar = TO_GAS_LIMIT / (TO_ELASTICITY * TARGET_BLOB_COUNT * 32,000)
                        = 1,200,000,000 / (15 * 21 * 32,000)
                        = 119
```

This targets a soft cap of 21 blobs per L1 block (~672,000 estimated bytes per L2 block).

The DA footprint scalar controls both:

- a soft cap, where DA footprint begins increasing the EIP-1559 base fee
- a hard cap, where DA footprint prevents further block inclusion

```
soft cap = (gas_limit / elasticity) / scalar
hard cap = gas_limit / scalar
```

With the new parameters (gas_limit=1.2B, elasticity=15, scalar=119):

- soft cap: ~672 KB per L2 block (~21 blobs per L1 block target)
- hard cap: ~10.1 MB per L2 block

> [!IMPORTANT] We have four transactions to sign (upgrade + rollback for each
> signer role). Please follow the flow below to sign all of them.

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

### 2. Install Node.js if needed

First, check if you have node installed

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node

```bash
brew install node
```

## Signing

### 1. Update repo:

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool (NOTE: do not enter the task directory. Run this command from the project's root).

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Select the correct signer role from the list of available users to sign. There are four
validation files — sign each one that corresponds to your signer role:

- **Base Signer** — primary upgrade (CB Multisig signers)
- **Security Council Signer** — primary upgrade (Security Council signers)
- **Base Signer Rollback** — rollback (CB Multisig signers)
- **Security Council Signer Rollback** — rollback (Security Council signers)

Copy each resulting signature and save it.

### 4. Send signatures to facilitator

Send all signatures to the facilitator, clearly noting which signer role and
which transaction (upgrade vs rollback) each signature corresponds to.

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
