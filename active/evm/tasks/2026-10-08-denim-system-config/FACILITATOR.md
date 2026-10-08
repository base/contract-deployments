# Denim SystemConfig Gas Parameters — Facilitator Guide

This task writes the post-Denim gas limit and EIP-1559 denominator to `SystemConfig`, signed by the
Base multisig alone (the `SystemConfig` owner).

At the first Denim block the node divides the gas limit by 10 and multiplies the EIP-1559
denominator by 10 (`DENIM_GAS_PARAMETER_SCALING_FACTOR` in base/base
`crates/consensus/derive/src/attributes/stateful.rs`). This task records the same values on L1 so
that a later `SystemConfig` update does not restore the 2s-block ones.

**Execute only after Denim activates.** Before it, the node would scale the new values a second time
when the fork lands. The script refuses to run before `DENIM_ACTIVATION_TIMESTAMP`.

Replace `<network>` with the rollout network (`zeronet`). Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory (`active/evm/tasks/2026-10-08-denim-system-config/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `OLD_GAS_LIMIT` and `OLD_EIP1559_DENOMINATOR` are the live `SystemConfig` values. The script asserts
  them before building the calls.
- `NEW_GAS_LIMIT` is `OLD_GAS_LIMIT / 10` and `NEW_EIP1559_DENOMINATOR` is
  `OLD_EIP1559_DENOMINATOR * 10`. The script asserts both ratios.
- `DENIM_ACTIVATION_TIMESTAMP` matches the activation registered in `ProtocolVersions`.

The EIP-1559 elasticity and the DA footprint gas scalar are read from the live config and must stay
unchanged.

## 3. Generate the validation file

After Denim activates:

```bash
make TASK_NETWORK=<network> gen-validation-cb
```

This writes `config/<network>/validations/base-signer.json`. Replace any generated
`<<ContractName>>` or `<<Summary>>` placeholders with reviewed contract names and state-change
descriptions. For any non-mainnet rollout, remove the generated `taskOriginConfig` and add this root
field:

```json
"skipTaskOriginValidation": true
```

Commit it and share `config/<network>/README.md` with signers.

## 4. Collect signatures and execute

`SystemConfig` is owned by the Base multisig directly, so the collected signatures execute the
transaction without a separate approval step.

```bash
SIGNATURES=<concatenated base signatures> make TASK_NETWORK=<network> execute
```

After execution the script checks the new gas limit and denominator, and that elasticity and the DA
footprint gas scalar are unchanged. Set the README status to the execution transaction link.
