# Activate Multiproof

Status: [EXECUTED](https://hoodi.etherscan.io/tx/0xbe0eb99650a815fbfed83ba6063a4c1dbe9444e2a55acda4d3a850fb825a5804)

## Description

This task activates multiproof on `zeronet`.

This task does not include the proposer-side follow-up steps after the upgrade.

## Procedure

## Sign Task

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

```bash
cd contract-deployments
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
