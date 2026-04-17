# Activate Multiproof

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xb20fcd230ee76842637a508382886aa7596f36dd6fc8f47d147aeab213fbd55d)

## Description

This task deploys and activates multiproof on `sepolia`.

It follows the same fresh-deploy + multisig activation flow as the Zeronet task, but deploys directly from the newer `BASE_CONTRACTS_COMMIT` so we do not need a separate follow-up upgrade task for the Nitro/TEE changes.

`CBMulticall` is already deployed on Sepolia, so this task starts directly at the Nitro deployment step.

Before collecting signatures, verify that the task parameters in `.env` match the intended Sepolia cutover values.

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
