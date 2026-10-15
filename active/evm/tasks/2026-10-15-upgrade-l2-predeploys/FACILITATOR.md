# Upgrade L2 Predeploys — Facilitator Guide

This task upgrades the `L2ToL1MessagePasser`, `L1Block`, `SequencerFeeVault`, `BaseFeeVault` and
`L1FeeVault` predeploys to their base/contracts implementations at `BASE_CONTRACTS_COMMIT`.

The L2 ProxyAdmin is owned by the L2 alias of the ProxyAdmin owner (the CB multisig and Security Council
Safe on L1). The task is one ProxyAdmin-owner transaction on L1 that sends five deposit transactions to
the L2 ProxyAdmin, one per predeploy. Each deposit is its own L2 call so that the ProxyAdmin sees the
aliased owner as the caller.

Fee vaults read their recipient, minimum withdrawal and withdrawal network from storage, which the
previous implementations kept in immutables. Their deposits use `upgradeAndCall` with `initialize`, so the
vaults never run with an empty config.

Replace `<network>` with the rollout network. Every command requires `TASK_NETWORK` explicitly. Run
everything from this directory (`active/evm/tasks/2026-10-15-upgrade-l2-predeploys/`).

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

## 2. Review the network config

Open `config/<network>/.env` and confirm the fee vault config that `initialize` writes:
`FEE_VAULT_RECIPIENT`, `FEE_VAULT_MIN_WITHDRAWAL_AMOUNT` and `FEE_VAULT_WITHDRAWAL_NETWORK` (`0` for L1,
`1` for L2). The same values apply to all three vaults.

## 3. Deploy the implementations

The implementations are deployed on L2, so the Ledger account needs ETH on L2.

```bash
make TASK_NETWORK=<network> deploy
```

`deploy` builds with 999999 optimizer runs and no bytecode hash, matching base/contracts' settings for
these contracts, checks each version, and writes the five addresses to
`config/<network>/addresses.json`.

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

The signing simulation cannot run deposits on L2, so the script replays them on an L2 fork as the aliased
owner and checks each predeploy's implementation and version, and the fee vault config.

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Replace
any generated `<<ContractName>>` or `<<Summary>>` placeholders with reviewed contract names and
state-change descriptions. For any non-mainnet rollout, remove the generated `taskOriginConfig` and add
this root field to each file:

```json
"skipTaskOriginValidation": true
```

Commit them and share `config/<network>/README.md` with signers.

## 5. Approve and execute

```bash
SIGNATURES=<concatenated base signatures> make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

The deposits take effect once L2 derives the L1 block. Then check each predeploy on L2:

```bash
cast call 0x4200000000000000000000000000000000000018 "getProxyImplementation(address)(address)" <predeploy> --rpc-url $L2_RPC_URL
cast call <predeploy> "version()(string)" --rpc-url $L2_RPC_URL
```

For the fee vaults, also check `recipient()`, `minWithdrawalAmount()` and `withdrawalNetwork()`. Set the
README status to the execution transaction link.
