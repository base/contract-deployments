# Fix TEE Image Hash

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x5040cdbab505f66c32db1b5d334325091243ea76a169053eab0b22b27c66c7e3)

## Description

This task redeploys `AggregateVerifier` on `zeronet` with a corrected `TEE_IMAGE_HASH` and registers the new implementation under game type `621` in the `DisputeGameFactory`.

`TEE_IMAGE_HASH` is an `immutable` of `AggregateVerifier`, so an in-place update is impossible. The fix therefore consists of:

- redeploying `AggregateVerifier` with identical immutables, overriding only `TEE_IMAGE_HASH` from `0xbcf94c238e15b5e423050df2b6f354ab2c5f3af791d8f862f654a195af9f491e` to `0x11fb64617dfa2875d31b0cfb656666fd8cee65eb134fefeca171b9b6b4444a64`
- pointing `DisputeGameFactory.gameImpls(621)` at the new implementation

No other contract is redeployed or upgraded. `TEEProverRegistry`, `NitroEnclaveVerifier`, `TEEVerifier`, `DelayedWETH`, and `AnchorStateRegistry` are untouched.

The task is intentionally split by caller permissions:

- Phase 1: deployer EOA runs `DeployAggregateVerifier`
- Phase 2: `PROXY_ADMIN_OWNER` multisig (nested `CB_MULTISIG` + `BASE_SECURITY_COUNCIL`) registers the new `AggregateVerifier` in the `DisputeGameFactory`

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
