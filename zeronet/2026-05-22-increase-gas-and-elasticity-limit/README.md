# Update Gas Limit, EIP-1559 Params & DA Footprint Gas Scalar in L1 `SystemConfig`

Status: READY TO SIGN

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

> [!IMPORTANT] We have two transactions to sign. Please follow
> the flow for both the upgrade and rollback signing steps below.

## Procedure

### Sign task

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

Select the **"Base Signer"** task (not the rollback) and sign. Copy the resulting signature.

Then switch to the **"Base Signer Rollback"** task and sign. Copy the resulting signature.

#### 4. Send signatures to facilitator

Send both signatures to the facilitator, clearly noting which is the primary upgrade and which is the rollback.

Close the signer tool with `Ctrl + C`.

For facilitator instructions, see `FACILITATOR.md`.
