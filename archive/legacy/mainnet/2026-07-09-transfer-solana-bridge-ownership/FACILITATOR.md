# Facilitator Guide

Guide for facilitators managing the Base mainnet Solana bridge owner transfer.

## 1. Generate the validation file

Run this after any change to [.env](./.env) or
[script/TransferSolanaBridgeOwnership.s.sol](./script/TransferSolanaBridgeOwnership.s.sol).

```bash
cd contract-deployments
git pull
cd mainnet/2026-07-09-transfer-solana-bridge-ownership
make deps
make gen-validation
```

This produces `validations/coinbase-signer.json`. Check that the `cmd` field uses:

```text
--sender 0x6CD3850756b7894774Ab715D136F9dD02837De50
```

(or whichever owner of `OWNER_SAFE` is set as `SENDER` in `.env`).

### Disable task-origin validation

This task does not ship task-origin signatures. After generating the validation
file, ensure `validations/coinbase-signer.json` carries the following fields at the
JSON root (add them if the signer-tool did not emit them automatically):

```json
"skipTaskOriginValidation": true,
"hideTaskOriginSkippedPage": true
```

Commit the file only after those fields are set; otherwise signers' UI will demand
task-origin attestations that do not exist for this task.

## 2. Collect signatures

Ask signers to follow [README.md](./README.md). They run `make sign-task` from the repo root and
select `mainnet/2026-07-09-transfer-solana-bridge-ownership` in the signing UI. The old multisig
has a threshold of 3, so collect at least 3 signatures.

## 3. Execute

This task uses direct signatures from `OWNER_SAFE`, so there are no separate nested Safe approval
transactions. Concatenate the collected signatures and pass them to `make execute`.

```bash
cd contract-deployments
git pull
cd mainnet/2026-07-09-transfer-solana-bridge-ownership
make deps
SIGNATURES=AAABBBCCC make execute
```

Replace `AAABBBCCC` with the concatenated signatures collected from signers.

## 4. Verify onchain

After the L1 deposits are relayed to L2, verify on Base mainnet that every contract is now controlled
by the new owner alias `0xa966054731540a48b28990b63Dcf4f33d8aE57B2`:

```bash
export RPC=https://mainnet.base.org
export FACTORY=0x0000000000006396FF2a80c067f99B3d2Ab4Df24

# Bridge: both the functional owner and the proxy admin must move.
cast call 0x3eff766C76a1be2Ce1aCF2B69c78bCae257D5188 "owner()(address)" --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0x3eff766C76a1be2Ce1aCF2B69c78bCae257D5188 --rpc-url $RPC

# Beacons.
cast call 0xb326c02150bb0De265Bb0eCeDA53531ab0163bf6 "owner()(address)" --rpc-url $RPC
cast call 0xddc41fda4b758728d07f4686dbe7d1c75c6b2552 "owner()(address)" --rpc-url $RPC

# Proxies (admin held in the factory).
cast call $FACTORY "adminOf(address)(address)" 0xDD56781d0509650f8C2981231B6C917f2d5d7dF2 --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0xAF24c1c24Ff3BF1e6D882518120fC25442d6794B --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0x8Cfa6F29930E6310B6074baB0052c14a709B4741 --rpc-url $RPC
```

Each call must return `0xa966054731540a48b28990b63Dcf4f33d8aE57B2`.

Then update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any
generated execution records.
