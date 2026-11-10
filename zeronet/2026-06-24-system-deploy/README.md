# zeronet system deploy

Full L1 system deployment on zeronet using `SystemDeploy.s.sol` from the sibling `contracts/` repo.


## Steps

### 0. Refresh genesis anchor values before executing

`multiproofGenesisBlockNumber` and `multiproofGenesisOutputRoot` must point to a block that is still available in the proof node at the time of deployment. Refresh them immediately before running `make simulate` or `make deploy`:

```sh
BLOCK=$(cast rpc optimism_syncStatus --rpc-url https://base-zeronet-reth-proofs-donotuse.cbhq.net:7545 | jq -r '.finalized_l2.number')
OUTPUT_ROOT=$(cast rpc optimism_outputAtBlock "$(printf '0x%x' "$BLOCK")" --rpc-url https://base-zeronet-reth-rpc-donotuse.cbhq.net:7545 | jq -r '.outputRoot')
echo "multiproofGenesisBlockNumber: $BLOCK"
echo "multiproofGenesisOutputRoot:  $OUTPUT_ROOT"
```

Update `deploy-config/zeronet.json` with the printed values before proceeding.

### 1. Simulate (no broadcast)

```sh
make simulate
```

### 2. Deploy (broadcast via Ledger)

```sh
make deploy
```
