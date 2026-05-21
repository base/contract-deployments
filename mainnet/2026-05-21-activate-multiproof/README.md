# Activate Multiproof

Status: READY TO SIGN

## Description

This task deploys and activates multiproof on Ethereum mainnet L1 for Base mainnet.

- deploys `NitroEnclaveVerifier`
- deploys the multiproof stack with `TEEVerifier`, `ZkVerifier`, and `AggregateVerifier`
- activates the new multiproof game type through the mainnet `ProxyAdminOwner`
- disables new `CANNON` game creation

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
