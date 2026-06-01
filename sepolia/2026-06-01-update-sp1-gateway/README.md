# Update SP1 Gateway

Status: READY TO SIGN

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
