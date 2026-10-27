# Rotate verifier hashes on sepolia

Status: READY TO SIGN

## Description

Register `<replacement-address>` instead of `0xB5abCf8656E3F26990ECEEEc99D22023E7eb7E3b` for game type `621` on `DisputeGameFactory` (`0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`).
Update `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH`; preserve `TEE_IMAGE_HASH` (`0x44cca4430eaac037ec451534ff7c9361095fa36e0f53fac9fa03f8305c879ef7`) and every other constructor input.

Hash provenance: `<source-revision, reproducible-build-evidence, SP1 vkeys>`.
Approvers: Base and Security Council through the ProxyAdmin owner Safe (`0x0fe884546476dDd290eC46318785046ef68a0BA9`).

Facilitator instructions: [FACILITATOR.md](../../FACILITATOR.md).

## Sign

From the repository root:

```sh
make TASK_NETWORK=sepolia sign-task
```

Select `update-verifier-hashes` for sepolia, sign, and send the signature to the facilitator.
