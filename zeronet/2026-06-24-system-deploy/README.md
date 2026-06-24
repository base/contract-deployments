# zeronet system deploy

Full L1 system deployment on zeronet using `SystemDeploy.s.sol` from the sibling `contracts/` repo.

## Prerequisites

Fill in all `"TODO"` placeholders in `deploy-config/zeronet.json` before running:

| Field | How to obtain |
|---|---|
| `finalSystemOwner` | Confirm with team (likely `PROXY_ADMIN_OWNER` or `CB_MULTISIG`) |
| `superchainConfigGuardian` | Confirm with team |
| `p2pSequencerAddress` | Check zeronet node config |
| `sp1Verifier` | Confirm verifier contract address |
| `baseFeeVaultRecipient` / `l1FeeVaultRecipient` / etc. | Confirm fee recipient addresses |
| `operatorFeeVaultRecipient` / `sequencerFeeVaultRecipient` | Confirm fee recipient addresses |
| `l2OutputOracleStartingTimestamp` | Genesis timestamp from chain config |
| `multiproofConfigHash` | Compute from multiproof config |
| `multiproofGenesisOutputRoot` | Fetch from chain at genesis block |
| `zkRangeHash` | `cast call <AGGREGATE_VERIFIER> "zkRangeHash()(bytes32)" --rpc-url <L1_RPC_URL>` |
| `zkAggregationHash` | `cast call <AGGREGATE_VERIFIER> "zkAggregationHash()(bytes32)" --rpc-url <L1_RPC_URL>` |

Active AggregateVerifier on zeronet: check `zeronet/.env` or existing task outputs.

## Steps

### 1. Simulate (no broadcast)

```sh
make simulate
```

Runs the deployment script against the live L1 RPC without broadcasting any transactions. Use this to validate configuration before spending gas.

### 2. Deploy (broadcast via Ledger)

```sh
make deploy
```

Broadcasts all transactions. Requires a Ledger connected and unlocked at account index `LEDGER_ACCOUNT` (set in `zeronet/.env`).

## Output

Broadcast records are written by Foundry to the contracts repo under:
```
contracts/broadcast/SystemDeploy.s.sol/<l1ChainId>/run-latest.json
```

Record deployed contract addresses from there and update `zeronet/.env` as needed.
