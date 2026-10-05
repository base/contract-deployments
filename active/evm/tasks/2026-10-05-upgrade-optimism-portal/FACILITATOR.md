# Upgrade OptimismPortal2 — Facilitator Guide

This task upgrades Base mainnet's `OptimismPortal2` from `6.0.0` to `7.0.1`, built from the
`base/contracts` commit pinned in `config/<network>/.env`.

Replace `<network>` with the rollout network, `mainnet`. Every command requires `TASK_NETWORK`
explicitly. Run everything from this directory
(`active/evm/tasks/2026-10-05-upgrade-optimism-portal/`).

## Source and version

`7.0.1` is built from base/contracts `main`, not from the `6.0.0` release that is live. Compared with
`6.0.0`, the new implementation drops the `superchainConfig()` passthrough getter, from the
SuperchainConfig merge into SystemConfig. No onchain contract calls it. Check offchain consumers
before execution.

It calls only `paused()`, `guardian()`, `isFeatureEnabled()` and `resourceConfig()` on
`SystemConfig`, all of which the live `3.14.0` `SystemConfig` provides. Storage layout and init
version are unchanged, so the upgrade is a bare `ProxyAdmin.upgrade`.

`BASE_CONTRACTS_COMMIT` is a commit on base/contracts `main`.

## 1. Install dependencies

```bash
make TASK_NETWORK=<network> deps
```

This pins `base/contracts` at `BASE_CONTRACTS_COMMIT` and installs the OpenZeppelin and solmate
versions that building `OptimismPortal2` from source requires.

## 2. Review the network config

Open `config/<network>/.env` and confirm:

- `BASE_CONTRACTS_COMMIT` is the reviewed base/contracts commit.
- `OLD_OPTIMISM_PORTAL_IMPL` is the live portal implementation. The upgrade script asserts it, and
  that the live version is `6.0.0`, before building the call.

## 3. Deploy and verify

```bash
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify
```

`deploy` builds with the `portal-deploy` profile (5000 optimizer runs, no bytecode hash, matching
base/contracts' settings for `OptimismPortal2`). It copies `proofMaturityDelaySeconds` from the live
portal, checks the new implementation's version and delay, and writes `optimismPortalImpl` and its
constructor arguments to `config/<network>/addresses.json`.

Commit `config/<network>/addresses.json` and the `records/` broadcast artifacts, then fill in the new
implementation address in `config/<network>/README.md`.

## 4. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`.
Replace any generated `<<ContractName>>` or `<<Summary>>` placeholders with reviewed contract names
and state-change descriptions. The only expected state change on the portal proxy is the EIP-1967
implementation slot moving from `OLD_OPTIMISM_PORTAL_IMPL` to the new implementation, plus the
Safe nonce and approval changes.

Commit them, then generate and commit the task-origin signatures:

```bash
make TASK_NETWORK=<network> sign-as-task-creator
make TASK_NETWORK=<network> sign-as-base-facilitator
make TASK_NETWORK=<network> sign-as-sc-facilitator
```

Share `config/<network>/README.md` with signers.

## 5. Collect signatures and execute

The ProxyAdmin owner is a 2-of-2 of the Base multisig and the Security Council, so each approves its
own nested Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

After execution the script checks that the proxy points at the new implementation, reports
`7.0.1`, and kept its ETH balance, `proofMaturityDelaySeconds`, `systemConfig`,
`anchorStateRegistry`, `l2Sender`, guardian and pause state. Set the README status to the execution
transaction link.
