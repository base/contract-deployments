# Increase Min Base Fee in `SystemConfig`

Status: READY TO SIGN

## Description

This task increases the `minBaseFee` parameter in SystemConfig from 200,000 wei to 500,000 wei (a 2.5x increase).

## Parameters

| Parameter | From | To |
|-----------|------|-----|
| minBaseFee | 200,000 wei | 500,000 wei |

## Signing Instructions

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

From the project root (not the task directory):

```bash
make sign-task
```

### 3. Open the UI

Open [http://localhost:3000](http://localhost:3000) and select this task from the list.

### 4. Send signature to facilitator

Copy the resulting signature and send it to the facilitator.

You may kill the Signer Tool process with `Ctrl + C`.
