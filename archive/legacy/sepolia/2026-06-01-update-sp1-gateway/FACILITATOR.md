# Facilitator Guide

Guide for facilitators managing this task.

## Deployment prerequisites

Before collecting signatures, complete the EOA-authorized phase:

```bash
cd contract-deployments
git pull
cd sepolia/2026-06-01-update-sp1-gateway
make deps
make deploy-sp1-gateway VERIFIER_API_KEY=...
make deploy-zk-verifier VERIFIER_API_KEY=...
make deploy-aggregate-verifier VERIFIER_API_KEY=...
```

`make deps` pins `succinctlabs/sp1-contracts` to commit
`22c4a47cd0a388cb4e25b4f2513954e4275c74ca` and installs the OpenZeppelin
dependency needed by `SP1VerifierGateway` under the package's expected path.

`make deploy-sp1-gateway` runs `DeploySp1Gateway`:

- deploys `SP1VerifierGateway` with `PROXY_ADMIN_OWNER` as owner
- confirms `SP1_VERIFIER_ROUTE` is not already set on the new gateway
- writes `sp1VerifierGateway` to `addresses.json`

`make deploy-zk-verifier` runs `DeployZkVerifier`:

- deploys `ZkVerifier` using `sp1VerifierGateway`
- preserves the current `AnchorStateRegistry` from the live `AggregateVerifier`
- writes `zkVerifier` to `addresses.json`

`make deploy-aggregate-verifier` runs `DeployAggregateVerifier`:

- redeploys `AggregateVerifier` with the same immutables as the current one
- replaces only `ZK_VERIFIER` with the newly deployed `zkVerifier`
- writes `aggregateVerifier` to `addresses.json`

Expected `addresses.json` keys:

- `sp1VerifierGateway`
- `zkVerifier`
- `aggregateVerifier`

## Generate validation files

```bash
cd contract-deployments
git pull
cd sepolia/2026-06-01-update-sp1-gateway
make deps
make gen-validation-update-sp1-gateway-cb
make gen-validation-update-sp1-gateway-sc
```

This produces:

- `validations/coinbase-signer.json`
- `validations/security-council-signer.json`

### Disable task-origin validation

This task does not ship task-origin signatures. After generating the two
validation files, ensure each one carries the following field at the JSON
root (add it if the signer-tool did not emit it automatically):

```json
"skipTaskOriginValidation": true
```

Commit both files only after that field is set; otherwise signers' UI will
demand task-origin attestations that do not exist for this task.

## Execute the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
cd sepolia/2026-06-01-update-sp1-gateway
make deps
```

### 2. Collect signatures for `CB_MULTISIG`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-sp1-gateway-cb
```

### 3. Collect signatures for `BASE_SECURITY_COUNCIL`

Concatenate all signatures and export as the `SIGNATURES` environment variable:

```bash
export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."
```

Then run:

```bash
SIGNATURES=$SIGNATURES make approve-update-sp1-gateway-sc
```

### 4. Execute upgrade batch

```bash
make execute-update-sp1-gateway
```

Post-checks enforced by script:

- `DisputeGameFactory.gameImpls(gameType)` equals the newly deployed `aggregateVerifier`
- `sp1VerifierGateway.owner()` equals `PROXY_ADMIN_OWNER`
- `sp1VerifierGateway.routes(selector)` points to `SP1_VERIFIER_ROUTE` and is not frozen
- `zkVerifier.SP1_VERIFIER()` equals the newly deployed `sp1VerifierGateway`
- `zkVerifier.ANCHOR_STATE_REGISTRY()` matches the live `AggregateVerifier`
- `aggregateVerifier.ZK_VERIFIER()` equals the newly deployed `zkVerifier`
- all other `AggregateVerifier` immutables match the previous `AggregateVerifier`
