# Rotate verifier hashes on zeronet

Status: READY TO SIGN

## Description

Register [`0xa8320712fF181D74e719Ff7E6E1012bbe4687b26`](https://hoodi.etherscan.io/address/0xa8320712fF181D74e719Ff7E6E1012bbe4687b26) ([deployment](https://hoodi.etherscan.io/tx/0x56da76c2c84b882f3fafeaf3835c2045730a0b1a850f12e13d52447de4b40c98)) instead of `0x4780D45fcf885a4D1F4c3aFDfAc9Eb9740820635` for game type `621` on `DisputeGameFactory` (`0xd930e0cebd52d7c77b8f900de242e818506c5474`).
Update `ZK_RANGE_HASH` and `ZK_AGGREGATE_HASH`; preserve `TEE_IMAGE_HASH` (`0x44cca4430eaac037ec451534ff7c9361095fa36e0f53fac9fa03f8305c879ef7`) and every other constructor input.

Hash provenance:
- `ZK_RANGE_HASH` (`0x3d3713d31a8936563bc56791040067131bb3fa3c0ab8b5e65e9c4cc0755b5fdb`) and `ZK_AGGREGATE_HASH` (`0x00d5a43068d7a9d1eac440a790b776c749ae6516c43f1a572226190cef6fd45a`): `just succinct vkeys --build` from `base/base` `releases/v1.5.2` ([`6efa75662b57c578d897fea2449035636f6ad9ad`](https://github.com/base/base/tree/6efa75662b57c578d897fea2449035636f6ad9ad)).
- `TEE_IMAGE_HASH` (`0x44cca4430eaac037ec451534ff7c9361095fa36e0f53fac9fa03f8305c879ef7`): unchanged (`cast keccak 0x2cbd0c628d01431b2417e71882a3c4eb9dd1144cb35859fc3074ef18b737efccebe5ad83d42f5daf1cc84128befd5056` from [`f3a459feaf4b071f311940510055b4b55b9374b8`](https://github.com/base/base/tree/f3a459feaf4b071f311940510055b4b55b9374b8)).

Approvers: Base and Security Council through the ProxyAdmin owner Safe (`0x3d59999977e0896ee1f8783bb8251df16fb483e9`).

Facilitator instructions: [FACILITATOR.md](../../FACILITATOR.md).

## Sign

From the repository root:

```sh
make TASK_NETWORK=zeronet sign-task
```

Select `update-verifier-hashes` for zeronet, sign, and send the signature to the facilitator.
