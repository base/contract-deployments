# Rotate verifier hashes on sepolia

Status: READY TO SIGN

## Description

Register `<replacement-address>` instead of `0xB5abCf8656E3F26990ECEEEc99D22023E7eb7E3b` for game type `621` on `DisputeGameFactory` (`0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`).
Update `TEE_IMAGE_HASH`, `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH`; preserve every other constructor input.

Hash provenance:
- `ZK_RANGE_HASH` (`0x3d3713d31a8936563bc56791040067131bb3fa3c0ab8b5e65e9c4cc0755b5fdb`) and `ZK_AGGREGATE_HASH` (`0x00d5a43068d7a9d1eac440a790b776c749ae6516c43f1a572226190cef6fd45a`): `just succinct vkeys --build` from `base/base` `releases/v1.5.2` ([`6efa75662b57c578d897fea2449035636f6ad9ad`](https://github.com/base/base/tree/6efa75662b57c578d897fea2449035636f6ad9ad)).
- `TEE_IMAGE_HASH` (`0x73181275ec86503b629510176b5bedec00309060b3f4ff5d8e55d9e83dad5cbd`, was `0x44cca4430eaac037ec451534ff7c9361095fa36e0f53fac9fa03f8305c879ef7`): `cast keccak 0x57f978efc999ccc8b14d15f3884902a75223c0f987137576183281fc067e34754d51bf4687fdfa4f57dc9261cd88136b`, the PCR0 of the Nitro enclave image built from the same commit.

Approvers: Base and Security Council through the ProxyAdmin owner Safe (`0x0fe884546476dDd290eC46318785046ef68a0BA9`).

Facilitator instructions: [FACILITATOR.md](../../FACILITATOR.md).

## Sign

From the repository root:

```sh
make TASK_NETWORK=sepolia sign-task
```

Select `update-verifier-hashes` for sepolia, sign, and send the signature to the facilitator.
