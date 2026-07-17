# Update Zeronet Incident Multisig Signers

Status: EXECUTED ([Incident Multisig](https://hoodi.etherscan.io/tx/0x2a72ea46e7be6ec516e882a78d56881482be1631d6539cdc0912aa957a893328) and [mock Security Council Safe](https://hoodi.etherscan.io/tx/0xb83040f4ae06e8f37442185b5753e7fc5c7088eef927e666c178739cdce60a3c))

## Transactions

- Incident Multisig update ([`0x856611eD7E07D83243b15E93f6321f2df6865852`](https://hoodi.etherscan.io/address/0x856611eD7E07D83243b15E93f6321f2df6865852)): [`0x2a72ea46e7be6ec516e882a78d56881482be1631d6539cdc0912aa957a893328`](https://hoodi.etherscan.io/tx/0x2a72ea46e7be6ec516e882a78d56881482be1631d6539cdc0912aa957a893328) (artefacts: [run-1784291029603.json](./records/UpdateSigners.s.sol/560048/run-1784291029603.json))
- Mock Security Council Safe update ([`0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA`](https://hoodi.etherscan.io/address/0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA)): [`0xb83040f4ae06e8f37442185b5753e7fc5c7088eef927e666c178739cdce60a3c`](https://hoodi.etherscan.io/tx/0xb83040f4ae06e8f37442185b5753e7fc5c7088eef927e666c178739cdce60a3c) (artefacts: [run-1784291616981.json](./records/UpdateSigners.s.sol/560048/run-1784291616981.json))

## Description

This task updates the owner set for the Zeronet Incident Multisig and mock Security Council Safe.

It adds one signer and removes two signers from each Safe. The signer changes are configured in [OwnerDiff.json](./OwnerDiff.json).

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run the signing tool

```bash
cd contract-deployments
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select `zeronet/2026-07-15-incident-multisig-signers`.
- Select `base-signer.json` to sign for the Incident Multisig.
- Select `security-council-signer.json` to sign for the mock Security Council Safe.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
