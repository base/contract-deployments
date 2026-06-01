# Update SP1 Gateway

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0x29acd1370136ecb5f548046b856e4581b7fc21d475b2e771c3008cb942f3a085)

## Transactions

- New `SP1VerifierGateway` deployment ([`0x60E2473b0806A0e41609F175ebD292cD75DF6369`](https://hoodi.etherscan.io/address/0x60E2473b0806A0e41609F175ebD292cD75DF6369)): [`0xcc044286f3a6e10555166320966ea1b7c997b879ed5780d51b9550d642af6a76`](https://hoodi.etherscan.io/tx/0xcc044286f3a6e10555166320966ea1b7c997b879ed5780d51b9550d642af6a76) (artefacts: [run-1780324485936.json](./records/DeploySp1Gateway.s.sol/560048/run-1780324485936.json))
- New `ZkVerifier` deployment ([`0xA6b7521C05742404C78Ed31E2B86dE737715C172`](https://hoodi.etherscan.io/address/0xA6b7521C05742404C78Ed31E2B86dE737715C172)): [`0x9283f48ac72b6f8392ffd5d5e9258b2b88cbb657531e4939528deb77518a1caa`](https://hoodi.etherscan.io/tx/0x9283f48ac72b6f8392ffd5d5e9258b2b88cbb657531e4939528deb77518a1caa) (artefacts: [run-1780324547881.json](./records/DeployZkVerifier.s.sol/560048/run-1780324547881.json))
- New `AggregateVerifier` deployment ([`0x2DF6E2864913d366d7E2008801EB659e9d9854A2`](https://hoodi.etherscan.io/address/0x2DF6E2864913d366d7E2008801EB659e9d9854A2)): [`0x36ea85f1539713db4d9a4c6c8487cf3e38f466ac1fa05eeb6f054a9335479c0b`](https://hoodi.etherscan.io/tx/0x36ea85f1539713db4d9a4c6c8487cf3e38f466ac1fa05eeb6f054a9335479c0b) (artefacts: [run-1780324610808.json](./records/DeployAggregateVerifier.s.sol/560048/run-1780324610808.json))
- Coinbase Multisig approval ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0x57bad2ea4d6f35301557963e38204d10b1a28e20e4d29b4f88e45fe0f103b3c0`](https://hoodi.etherscan.io/tx/0x57bad2ea4d6f35301557963e38204d10b1a28e20e4d29b4f88e45fe0f103b3c0) (artefacts: [run-1780330611715.json](./records/UpdateSp1Gateway.s.sol/560048/run-1780330611715.json))
- Security Council approval ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0x5d9c6a4807482db5ebdcfe7eb2ecfb75c47b75625faf68f099565950e6ebcbeb`](https://hoodi.etherscan.io/tx/0x5d9c6a4807482db5ebdcfe7eb2ecfb75c47b75625faf68f099565950e6ebcbeb) (artefacts: [run-1780330681623.json](./records/UpdateSp1Gateway.s.sol/560048/run-1780330681623.json))
- Execute via Proxy Admin Owner ([`0x3d59999977e0896ee1f8783bB8251DF16fb483E9`](https://hoodi.etherscan.io/address/0x3d59999977e0896ee1f8783bB8251DF16fb483E9)): [`0x29acd1370136ecb5f548046b856e4581b7fc21d475b2e771c3008cb942f3a085`](https://hoodi.etherscan.io/tx/0x29acd1370136ecb5f548046b856e4581b7fc21d475b2e771c3008cb942f3a085) (artefacts: [run-1780330717465.json](./records/UpdateSp1Gateway.s.sol/560048/run-1780330717465.json))

## Description

This task updates the multiproof ZK verifier path on `zeronet` to use a `PROXY_ADMIN_OWNER`-owned SP1 verifier gateway.

- deploys a new `SP1VerifierGateway` from a pinned `succinctlabs/sp1-contracts` commit
- sets `PROXY_ADMIN_OWNER` as the new gateway owner
- deploys a new `ZkVerifier` pointing at the new gateway
- deploys a new `AggregateVerifier` preserving the existing multiproof immutables except `ZK_VERIFIER`
- adds the current SP1 Groth16 verifier route and points `DisputeGameFactory.gameImpls(gameType)` at the new `AggregateVerifier`

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run signing tool

```bash
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.

## Troubleshooting

If the signer UI fails validation after dependency installation times out, pre-install the task dependencies and restart the signer tool:

```bash
cd contract-deployments/zeronet/2026-05-31-update-sp1-gateway
rm -rf lib
make deps
cd ../../
make sign-task
```

The task Makefile already runs Foundry and Node commands through `mise exec --` internally. If validation still fails because the wrong `forge` version is being used, or because the signer tool cannot find `mise`, make sure `mise` is available on your `PATH`. If `mise` was installed to `~/.local/bin/mise`, add `~/.local/bin` to your `PATH`, restart your shell, and then rerun `make sign-task`. As a manual check, `mise exec -- forge --version` should report the repo-pinned Foundry version.
