# Rotate verifier hashes on zeronet

Status: READY TO SIGN

## Description

Register `<replacement-address>` instead of `0x4780D45fcf885a4D1F4c3aFDfAc9Eb9740820635` for game type `621` on `DisputeGameFactory` (`0xd930e0cebd52d7c77b8f900de242e818506c5474`).
Update `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH`; preserve `TEE_IMAGE_HASH` (`0x44cca4430eaac037ec451534ff7c9361095fa36e0f53fac9fa03f8305c879ef7`) and every other constructor input.

Hash provenance: `<source-revision, reproducible-build-evidence, SP1 vkeys>`.
Approvers: Base and Security Council through the ProxyAdmin owner Safe (`0x3d59999977e0896ee1f8783bb8251df16fb483e9`).

Facilitator instructions: [FACILITATOR.md](../../FACILITATOR.md).

## Sign

From the repository root:

```sh
make TASK_NETWORK=zeronet sign-task
```

Select `update-verifier-hashes` for zeronet, sign, and send the signature to the facilitator.
