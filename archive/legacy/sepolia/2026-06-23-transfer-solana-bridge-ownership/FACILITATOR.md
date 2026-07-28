# Facilitator Guide

Guide for facilitators managing the Base Sepolia Solana bridge owner transfer.

## 1. Generate the validation file

Run this after any change to [.env](./.env) or
[script/TransferSolanaBridgeOwnership.s.sol](./script/TransferSolanaBridgeOwnership.s.sol).

```bash
cd contract-deployments
git pull
cd sepolia/2026-06-23-transfer-solana-bridge-ownership
make deps
make gen-validation
```

This produces `validations/base-signer.json`. Check that the `cmd` field uses:

```text
--sender 0x6e427c3212C0b63BE0C382F97715D49b011bFF33
```

(or whichever owner of `OWNER_SAFE` is set as `SENDER` in `.env`).

### Disable task-origin validation

This task does not ship task-origin signatures. After generating the validation
file, ensure `validations/base-signer.json` carries the following field at the JSON
root (add it if the signer-tool did not emit it automatically):

```json
"skipTaskOriginValidation": true
```

Commit the file only after that field is set; otherwise signers' UI will demand
task-origin attestations that do not exist for this task.

## 2. Collect signatures

Ask signers to follow [README.md](./README.md). They run `make sign-task` from the repo root and
select `sepolia/2026-06-23-transfer-solana-bridge-ownership` in the signing UI. The old multisig
has a threshold of 3, so collect at least 3 signatures.

## 3. Execute

This task uses direct signatures from `OWNER_SAFE`, so there are no separate nested Safe approval
transactions. Concatenate the collected signatures and pass them to `make execute`.

```bash
cd contract-deployments
git pull
cd sepolia/2026-06-23-transfer-solana-bridge-ownership
make deps
SIGNATURES=AAABBBCCC make execute
```

Replace `AAABBBCCC` with the concatenated signatures collected from signers.

## 4. Verify on-chain

After the L1 deposits are relayed to L2, verify on Base Sepolia that every contract is now controlled
by the new owner alias `0x757232A1667ca7aD00d36616AFBA1A28116C881B`:

```bash
export RPC=https://sepolia.base.org
export FACTORY=0x0000000000006396FF2a80c067f99B3d2Ab4Df24

# Bridge: both the functional owner and the proxy admin must move.
cast call 0x01824a90d32A69022DdAEcC6C5C14Ed08dB4EB9B "owner()(address)" --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0x01824a90d32A69022DdAEcC6C5C14Ed08dB4EB9B --rpc-url $RPC

# Beacons.
cast call 0x11bF22cFf007C46C725Dc59A919383326E3cdefB "owner()(address)" --rpc-url $RPC
cast call 0xc039781ccb3cb281f69f8509bfb17163993dd6d1 "owner()(address)" --rpc-url $RPC

# Proxies (admin held in the factory).
cast call $FACTORY "adminOf(address)(address)" 0x488EB7F7cb2568e31595D48cb26F63963Cc7565D --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0x863Bed3E344035253CC44C75612Ad5fDF5904aEE --rpc-url $RPC
cast call $FACTORY "adminOf(address)(address)" 0x1e0842b2E6FA06A59b05a9c1d36a6480730012CE --rpc-url $RPC
```

Each call must return `0x757232A1667ca7aD00d36616AFBA1A28116C881B`.

Then update [README.md](./README.md) status to `EXECUTED` with the transaction link and check in any
generated execution records.
