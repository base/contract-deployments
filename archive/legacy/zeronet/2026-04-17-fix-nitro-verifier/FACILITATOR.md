# Facilitator Guide

Guide for facilitators managing this task.

## Generate validation file

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-nitro-verifier
make deps
make gen-validation
```

This produces `validations/fix-nitro-verifier-cb-signer.json`, which signers should use in the signing UI.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd zeronet/2026-04-17-fix-nitro-verifier
make deps
```

### 2. Collect signatures from all participating signers

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

### 3. Execute

```bash
SIGNATURES=$SIGNATURES make execute
```

Post-checks enforced by the script:

- `NitroEnclaveVerifier.owner()` remains `TEE_PROVER_REGISTRY_OWNER`
- `NitroEnclaveVerifier.proofSubmitter()` remains unchanged
- `NitroEnclaveVerifier.revoker()` remains unchanged
- `NitroEnclaveVerifier.maxTimeDiff()` remains unchanged
- `NitroEnclaveVerifier.rootCert()` remains unchanged
- `NitroEnclaveVerifier.getZkConfig(RiscZero).verifierId` equals `NITRO_ZK_VERIFIER_ID`
- `NitroEnclaveVerifier.getZkConfig(RiscZero).aggregatorId` remains unchanged
- `NitroEnclaveVerifier.getZkConfig(RiscZero).zkVerifier` remains unchanged
- `NitroEnclaveVerifier.getVerifierProofId(RiscZero)` remains unchanged
