# Zeronet Facilitator Notes

Status: EXECUTED. Preserve these artifacts as historical records and do not regenerate the Zeronet validations.

Use `TASK_NETWORK=zeronet` when inspecting the completed configuration.

## Artifacts

- Deployment addresses: `config/zeronet/addresses.json`
- Forge records chain ID: `560048`
- Signer README and status: `config/zeronet/README.md`

## Validation

The committed validation files already skip task-origin validation.

The executed forward transition changed the TEE registry implementation from `0x98ff839d2671bbaf6394bf03a496ea634f8a39c8` to the implementation in `config/zeronet/addresses.json`.

The rollback configuration restores implementation `0x98ff839d2671bbaf6394bf03a496ea634f8a39c8` and legacy Nitro verifier `0xDC06089B0224e59bAAa9B59c3C5aAF9Ff105997C`.

## Offchain Cutover

The migrated registrar uses signer `0x5F109182a097c40Cc936742be4B55c1A08aC4dd9` and retains `BASE_REGISTRAR_CRL_NITRO_VERIFIER_ADDRESS` for rollback.
