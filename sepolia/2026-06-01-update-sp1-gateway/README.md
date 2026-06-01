# Update SP1 Gateway

Status: READY TO SIGN

## Transactions

- New `SP1VerifierGateway` deployment ([`0x07967e51F0d9b60294E7D746162438298B71F868`](https://sepolia.etherscan.io/address/0x07967e51F0d9b60294E7D746162438298B71F868)): [`0xf4efe7e1370f71e29b90577174382315bf60e600ea14bfadabce96a5d87df271`](https://sepolia.etherscan.io/tx/0xf4efe7e1370f71e29b90577174382315bf60e600ea14bfadabce96a5d87df271) (artefacts: [run-1780334248135.json](./records/DeploySp1Gateway.s.sol/11155111/run-1780334248135.json))
- New `ZkVerifier` deployment ([`0xa738E13d97A3f10b307C2CD190edd3E227A72D68`](https://sepolia.etherscan.io/address/0xa738E13d97A3f10b307C2CD190edd3E227A72D68)): [`0x5e0f25894c4f3fdd7f48f566b6205531b45c45fbe5b88b2131c63ccbc45eea25`](https://sepolia.etherscan.io/tx/0x5e0f25894c4f3fdd7f48f566b6205531b45c45fbe5b88b2131c63ccbc45eea25) (artefacts: [run-1780334336796.json](./records/DeployZkVerifier.s.sol/11155111/run-1780334336796.json))
- New `AggregateVerifier` deployment ([`0xc45dC8a279b2fDB7efEF72044e53514eD1bc2c08`](https://sepolia.etherscan.io/address/0xc45dC8a279b2fDB7efEF72044e53514eD1bc2c08)): [`0x572a9c4c7b5daebd57dc40e6715955352f45059253b3e89f7b3f5dd1a76d6984`](https://sepolia.etherscan.io/tx/0x572a9c4c7b5daebd57dc40e6715955352f45059253b3e89f7b3f5dd1a76d6984) (artefacts: [run-1780334861591.json](./records/DeployAggregateVerifier.s.sol/11155111/run-1780334861591.json))

## Description

This task updates the multiproof ZK verifier path on `sepolia` to use a `PROXY_ADMIN_OWNER`-owned SP1 verifier gateway.

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
cd contract-deployments/sepolia/2026-06-01-update-sp1-gateway
rm -rf lib
make deps
cd ../../
make sign-task
```

The task Makefile already runs Foundry and Node commands through `mise exec --` internally. If validation still fails because the wrong `forge` version is being used, or because the signer tool cannot find `mise`, make sure `mise` is available on your `PATH`. If `mise` was installed to `~/.local/bin/mise`, add `~/.local/bin` to your `PATH`, restart your shell, and then rerun `make sign-task`. As a manual check, `mise exec -- forge --version` should report the repo-pinned Foundry version.
