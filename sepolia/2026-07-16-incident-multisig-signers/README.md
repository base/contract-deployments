# Update Sepolia Incident Multisig Signers

Status: EXECUTED ([Incident Multisig](https://sepolia.etherscan.io/tx/0xacce1d58975453f06be70f55d51f282e406b4edd3a0ffdb4d00cc99f1d7ff8d2) and [mock Security Council Safe](https://sepolia.etherscan.io/tx/0xf1024dc60d296fd405172aeadff2e979e016efa291ecdf4ede44546e055c01f5))

## Transactions

- Incident Multisig update ([`0x646132A1667ca7aD00d36616AFBA1A28116C770A`](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A)): [`0xacce1d58975453f06be70f55d51f282e406b4edd3a0ffdb4d00cc99f1d7ff8d2`](https://sepolia.etherscan.io/tx/0xacce1d58975453f06be70f55d51f282e406b4edd3a0ffdb4d00cc99f1d7ff8d2) (artefacts: [run-1784323322624.json](./records/UpdateSigners.s.sol/11155111/run-1784323322624.json))
- Mock Security Council Safe update ([`0x6AF0674791925f767060Dd52f7fB20984E8639d8`](https://sepolia.etherscan.io/address/0x6AF0674791925f767060Dd52f7fB20984E8639d8)): [`0xf1024dc60d296fd405172aeadff2e979e016efa291ecdf4ede44546e055c01f5`](https://sepolia.etherscan.io/tx/0xf1024dc60d296fd405172aeadff2e979e016efa291ecdf4ede44546e055c01f5) (artefacts: [run-1784323441942.json](./records/UpdateSigners.s.sol/11155111/run-1784323441942.json))

## Description

This task updates the owner set for the Sepolia Incident Multisig and mock Security Council Safe.

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

- Select `sepolia/2026-07-16-incident-multisig-signers`.
- Select `base-signer.json` to sign for the Incident Multisig.
- Select `security-council-signer.json` to sign for the mock Security Council Safe.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
