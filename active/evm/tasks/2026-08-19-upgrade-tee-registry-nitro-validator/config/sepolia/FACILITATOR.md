# Sepolia Facilitator Notes

Use `TASK_NETWORK=sepolia` for every command in the root facilitator guide.

## Artifacts

- Deployment addresses: `config/sepolia/addresses.json`
- Forge records chain ID: `11155111`
- Signer README and status: `config/sepolia/README.md`

## Validation

Remove each generated `taskOriginConfig` and add this root field to all four validation files:

```json
"skipTaskOriginValidation": true
```

Confirm the forward validation changes the TEE registry implementation from `0xF9Ab55c35cE7Fb183A50E611B63558499130D849` to the implementation in `config/sepolia/addresses.json`.

Confirm the rollback validation restores implementation `0xF9Ab55c35cE7Fb183A50E611B63558499130D849`, points back to legacy Nitro verifier `0x7D8EA07DB94128DBEe66bAfa3eBAa9668B413d72`, and uses the planned post-upgrade Safe nonces.

## Offchain Cutover

Confirm the migrated registrar uses signer `0x8074b32bD7d06C8f27596F3D6fbf867A36eA22a3` and retains `BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` for rollback.
