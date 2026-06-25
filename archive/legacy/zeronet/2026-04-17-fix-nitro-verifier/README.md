# Fix Nitro Verifier ID

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x3b7898e2c9b47b5000ba09cf67933c6b98027a4e49eecfe00539ad8e7f2e08ce)

## Description

This task updates the live Zeronet `NitroEnclaveVerifier` (`0x4e3E30E148E803667913bE97A8ce9EBA39b65563`) to use the corrected RISC Zero verifier program ID.

It is a single-call multisig task that invokes `updateVerifierId` for the RISC Zero path, changing the Nitro verifier ID from `0xce17a683c290c57ff91f00d4c0e6e6ec8aa2f73285af7d81b162327ba96321d6` to `0x15051db631d6ed382d957c795a558a0abdd00d0d22a1670455721bc2712d3d6e`.

The task starts from the post-execution state of the executed Zeronet upgrade task in [PR #663](https://github.com/base/contract-deployments/pull/663). It does not redeploy `NitroEnclaveVerifier`, `TEEProverRegistry`, or `AggregateVerifier`. It preserves the current Nitro owner, proof submitter, revoker, root cert, max time diff, router, aggregator ID, and verifier proof ID.

## Procedure

### Sign task

#### 1. Update repo and install deps

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-nitro-verifier
make deps
```

#### 2. Run the signing tool

```bash
cd contract-deployments
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

Select the correct task user from the list of available users and sign the transaction.

#### 4. Send the signature to the facilitator

Facilitator execution steps are documented in `FACILITATOR.md`.
