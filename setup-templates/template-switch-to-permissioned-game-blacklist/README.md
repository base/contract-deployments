# Switch to Permissioned Game and Blacklist Addresses

Status: PENDING

## Description

This task contains scripts that will blacklist fault dispute games after a provided L2 block number in the AnchorStateRegistry.
This can only be done by the "Optimism Guardian Multisig" which is a single-nested multisig controlled by the OP Security Council.

Because this requires searching through all dispute games, the time required for the task to execute may take some time. There are
two options:

1. If the `ADDRESSES_TO_BLACKLIST` environment variable is NOT set, the forge script will attempt to search for dispute games
   Note: this may take 10+ minutes

2. If the `ADDRESSES_TO_BLACKLIST` environment variable IS set, the forge script will NOT search and will just blacklist the addresses
   provided.

   There is a python script provided that can be run with `make find-dispute-games-offchain` that will use the provided
   RPC_URL to search for the list of games to blacklist _offchain_. This typically takes a minute or two. The output
   is the comma-separated `ADDRESSES_TO_BLACKLIST` environment variable that can be copied over to the `.env` file, so that
   the forge script can directly blacklist just those addresses.

## Install dependencies

### 1. Update foundry

```bash
foundryup
```

### 2. Install Node.js if needed

First, check if you have node installed

```bash
node --version
```

If you see a version output from the above command, you can move on. Otherwise, install node

```bash
brew install node
```

## Sign Task

### 1. Update repo:

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool (NOTE: do not enter the task directory. Run this command from the project's root).

```bash
make sign-task
```

### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

### 4. Send signature to facilitator

You may now kill the Signer Tool process in your terminal window by running `Ctrl + C`.
