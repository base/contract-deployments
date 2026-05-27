# Update AggregateVerifier (Game Type 621)

Status: READY TO SIGN

## Description

This task rotates the `AggregateVerifier` implementation registered for
multiproof game type `621` on Base mainnet's L1 `DisputeGameFactory`.

A freshly deployed `AggregateVerifier` is wired into the same multiproof stack
deployed in `mainnet/2026-05-21-activate-multiproof` (same `TEEVerifier`,
`ZkVerifier`, `DelayedWETH` proxy, and `AnchorStateRegistry` proxy). The only
differences between the old and new implementations are:

- a new `TEE_IMAGE_HASH`
- a new `ZK_RANGE_HASH`
- a new `ZK_AGGREGATE_HASH`

The on-chain change is a single `DisputeGameFactory.setImplementation(GameType.wrap(621), newAggregateVerifier, "")`
call routed through the mainnet `PROXY_ADMIN_OWNER` 2/2 nested safe
(`CB_MULTISIG` + `BASE_SECURITY_COUNCIL`).

A matching rollback transaction is also produced, which restores the previous
`AggregateVerifier` (`OLD_AGGREGATE_VERIFIER` in `.env`) onto game type `621`.

> [!IMPORTANT]
> Four validation files are produced (upgrade + rollback for each signer
> role). Sign every file that corresponds to your signer role.

## Sign Task

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

```bash
cd contract-deployments
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Select the correct signer role and sign each validation file that applies to
you:

- **Coinbase Signer** — primary upgrade (CB Multisig signers)
- **Security Council Signer** — primary upgrade (Security Council signers)
- **Coinbase Signer Rollback** — rollback (CB Multisig signers)
- **Security Council Signer Rollback** — rollback (Security Council signers)

After completion, close the signer tool with `Ctrl + C`.

### 4. Send signatures to facilitator

Copy each signature output and send it to the designated facilitator via the
agreed communication channel, clearly noting which signer role and which
transaction (upgrade vs rollback) each signature corresponds to.

For facilitator instructions, see `FACILITATOR.md`.
