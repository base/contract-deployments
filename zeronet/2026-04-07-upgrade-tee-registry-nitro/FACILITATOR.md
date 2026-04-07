# Facilitator Runbook - Upgrade TEEProverRegistry Nitro Pointer

This runbook executes the task in two phases with different authorization contexts.

## Phase 1 - EOA deploy and owner-only Nitro setup

Caller: deployer EOA (Ledger)

From task directory:

```bash
make deps
make deploy-and-setup LEDGER_ACCOUNT=<ledger_account_index> L1_RPC_URL=<l1_rpc_url>
```

Expected outputs:

- `addresses.json` contains:
  - `riscZeroSetVerifier`
  - `nitroEnclaveVerifier`
  - `teeProverRegistryImpl`
  - `riscZeroVerifierRouter`

Checks enforced by script:

- Nitro route wiring is set for set-verifier selector.
- Nitro `proofSubmitter` is the existing `TEE_PROVER_REGISTRY_PROXY`.
- Nitro `revoker` is `NITRO_REVOKER`.
- Nitro owner is transferred to `TEE_PROVER_REGISTRY_OWNER`.
- New TEE implementation immutables point to new Nitro and existing DGF proxy.

## Phase 2 - Multisig upgrade of TEE proxy

Caller: `PROXY_ADMIN_OWNER` safe signers

1) Generate validation:

```bash
make gen-validation-upgrade-tee LEDGER_ACCOUNT=<ledger_account_index> L1_RPC_URL=<l1_rpc_url>
```

2) Collect signatures in signer tool and set `SIGNATURES`.

3) Approve:

```bash
make approve-upgrade-tee LEDGER_ACCOUNT=<ledger_account_index> L1_RPC_URL=<l1_rpc_url> SIGNATURES=<signatures_blob>
```

4) Execute:

```bash
make execute-upgrade-tee LEDGER_ACCOUNT=<ledger_account_index> L1_RPC_URL=<l1_rpc_url>
```

Checks enforced by script:

- `TEE_PROVER_REGISTRY_PROXY` implementation equals new `teeProverRegistryImpl`.
- `TEEProverRegistry(proxy).NITRO_VERIFIER()` equals new `nitroEnclaveVerifier`.
