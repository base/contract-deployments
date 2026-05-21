# Update Nitro Verifier ID

Status: DRAFT

## Description

This task updates the live Zeronet `NitroEnclaveVerifier` (`0x4e3E30E148E803667913bE97A8ce9EBA39b65563`) to use the Boundless RISC Zero image ID for Nitro attestation proofs.

It is a single-call multisig task that invokes `updateVerifierId` for the RISC Zero path, changing the Nitro verifier ID from `0x15051db631d6ed382d957c795a558a0abdd00d0d22a1670455721bc2712d3d6e` to `0x20141665fe40bce01fbcfa0a95c8a1bd750eadbe3f24e06a75571e6fd7a9dc11`.

The task does not redeploy `NitroEnclaveVerifier`, `TEEProverRegistry`, or `AggregateVerifier`. It preserves the current Nitro owner, proof submitter, revoker, root cert, max time diff, router, aggregator ID, and verifier proof ID.

## Procedure

### Sign task

#### 1. Update repo and install deps

```bash
cd contract-deployments
git pull
cd zeronet/2026-05-21-update-nitro-verifier-id
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
