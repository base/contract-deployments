# Fix Nitro Verifier ID

Status: READY TO SIGN

## Description

This task updates Zeronet `NitroEnclaveVerifier` to use the RISC Zero guest image that the registrar sends to Boundless.

It changes the RISC Zero verifier ID from `0x15051db631d6ed382d957c795a558a0abdd00d0d22a1670455721bc2712d3d6e` to `0x20141665fe40bce01fbcfa0a95c8a1bd750eadbe3f24e06a75571e6fd7a9dc11`.

No verifier route, proof submitter, certificate configuration, or ownership changes.

## Sign

Run the signing tool from the repository root, then sign `base-signer.json`.

For execution steps, see `FACILITATOR.md`.
