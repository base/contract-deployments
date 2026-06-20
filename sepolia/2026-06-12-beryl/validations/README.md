# Validations: Sepolia Beryl Upgrade

This directory holds the auto-generated multisig transaction simulation and validation files for the `2026-06-12-beryl` upgrade task.

## Verification Checklist for Signers

Before applying your cryptographic signature to the batch, run the simulation targets and verify the generated JSON state outputs against the following parameters:

### 1. Verification of Environmental Hashes (`.env`)
Ensure that the newly generated artifacts match the exact parameters specified for the Beryl hardware environment update:
- **`TEE_IMAGE_HASH`**: Must represent the target trusted execution environment binary state hash.
- **`ZK_RANGE_HASH`**: Must map to the correct zero-knowledge proof validity ranges.
- **`ZK_AGGREGATE_HASH`**: Must correctly match the optimized circuit verification root.

> ⚠️ **CRITICAL SAFETY CHECK:** The state generator will automatically reject any inputs pointing to empty or `0x000...000` zeroed hashes to eliminate placeholder vulnerabilities.

### 2. Output Target Artifacts
Generating validation data outputs two core tracking files:
* `validations/coinbase-signer.json` (For checking Coinbase Multisig governance targets)
* `validations/security-council-signer.json` (For checking Base Security Council targets)

Verify that the `disputeGameFactory` parameters listed within these JSON execution records point exactly to the newly deployed `AggregateVerifier` proxy address tracked inside `addresses.json`.

