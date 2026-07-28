# Update SP1 Gateway

Status: [EXECUTED](https://etherscan.io/tx/0xb7ad31567dc133740576aa5d128b15989de6769df327763011fc7464f72c0132)

## Transactions

- New `SP1VerifierGateway` deployment ([`0xdc32E228636273285Befa5F001dBB5142517C106`](https://etherscan.io/address/0xdc32E228636273285Befa5F001dBB5142517C106)): [`0x4d86e5b5f7258da3c81c0d7f30ad2d58f988c79c7ec8b02f2ec38a46efae414b`](https://etherscan.io/tx/0x4d86e5b5f7258da3c81c0d7f30ad2d58f988c79c7ec8b02f2ec38a46efae414b) (artefacts: [run-1780357524520.json](./records/DeploySp1Gateway.s.sol/1/run-1780357524520.json))
- New `ZkVerifier` deployment ([`0xB88D95bDf6972508942d184866890c1834219B75`](https://etherscan.io/address/0xB88D95bDf6972508942d184866890c1834219B75)): [`0xdf4df8a4b0d7b929634d2cd88b9cc6c334d446739c365e25b773a2cb835cd99d`](https://etherscan.io/tx/0xdf4df8a4b0d7b929634d2cd88b9cc6c334d446739c365e25b773a2cb835cd99d) (artefacts: [run-1780357705138.json](./records/DeployZkVerifier.s.sol/1/run-1780357705138.json))
- New `AggregateVerifier` deployment ([`0xeEcb8A5944B217585817E802702b1262a049D259`](https://etherscan.io/address/0xeEcb8A5944B217585817E802702b1262a049D259)): [`0x7f0529b472d6ac2f4a265a9c8cbc4b7f52cafe3ae407b7794010de41c778eb97`](https://etherscan.io/tx/0x7f0529b472d6ac2f4a265a9c8cbc4b7f52cafe3ae407b7794010de41c778eb97) (artefacts: [run-1780357825461.json](./records/DeployAggregateVerifier.s.sol/1/run-1780357825461.json))
- Coinbase Multisig approval ([`0x9855054731540A48b28990B63DcF4f33d8AE46A1`](https://etherscan.io/address/0x9855054731540A48b28990B63DcF4f33d8AE46A1)): [`0x0861e5740f7ded588b4d9cc6c8154e736d2d831c748a8af098507c3868dc57d4`](https://etherscan.io/tx/0x0861e5740f7ded588b4d9cc6c8154e736d2d831c748a8af098507c3868dc57d4) (artefacts: [run-1780422793669.json](./records/UpdateSp1Gateway.s.sol/1/run-1780422793669.json))
- Security Council approval ([`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`](https://etherscan.io/address/0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd)): [`0x1ba4127c3a301826fba49f452846741144fc645ef7136cbf7df9140307e4d375`](https://etherscan.io/tx/0x1ba4127c3a301826fba49f452846741144fc645ef7136cbf7df9140307e4d375) (artefacts: [run-1780422999638.json](./records/UpdateSp1Gateway.s.sol/1/run-1780422999638.json))
- Execute via Proxy Admin Owner ([`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`](https://etherscan.io/address/0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c)): [`0xb7ad31567dc133740576aa5d128b15989de6769df327763011fc7464f72c0132`](https://etherscan.io/tx/0xb7ad31567dc133740576aa5d128b15989de6769df327763011fc7464f72c0132) (artefacts: [run-1780423646194.json](./records/UpdateSp1Gateway.s.sol/1/run-1780423646194.json))

## Description

This task updates the multiproof ZK verifier path on `mainnet` to use a `PROXY_ADMIN_OWNER`-owned SP1 verifier gateway.

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
cd contract-deployments/mainnet/2026-06-01-update-sp1-gateway
rm -rf lib
make deps
cd ../../
make sign-task
```

The task Makefile already runs Foundry and Node commands through `mise exec --` internally. If validation still fails because the wrong `forge` version is being used, or because the signer tool cannot find `mise`, make sure `mise` is available on your `PATH`. If `mise` was installed to `~/.local/bin/mise`, add `~/.local/bin` to your `PATH`, restart your shell, and then rerun `make sign-task`. As a manual check, `mise exec -- forge --version` should report the repo-pinned Foundry version.
