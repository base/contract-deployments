# Upgrade TEEProverRegistry Nitro Pointer

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0xca03ee8d7bf83e660523910113cb64f75c15baab35777e75bbcb6dc2c8efdd3a)

## Description

This task upgrades the `TEEProverRegistry` proxy on `zeronet` to a new implementation that points to a newly deployed `NitroEnclaveVerifier` with:

- certificate expiry-aware caching
- revoker role support

The task is intentionally split by caller permissions:

- Phase 1: deployer EOA runs 3 scripts in order:
  - `DeployAndSetupNitro`
  - `DeployTeeProverRegistryImpl`
  - `DeployAggregateVerifier`
- Phase 2: ProxyAdmin owner multisig upgrades the TEE proxy and registers the new AggregateVerifier in the DisputeGameFactory

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run signing tool

```bash
cd contract-deployments
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
