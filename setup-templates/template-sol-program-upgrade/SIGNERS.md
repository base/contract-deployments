# Signing Instructions for Solana Program Upgrade

This document contains instructions for **signers only**. If you are the Facilitator, please refer to the main [README.md](./README.md).

## Procedure

### 1. Update repo:

```bash
cd contract-deployments
git pull
make setup-sol-program-upgrade network=<network>
cd <network>/<date>-sol-program-upgrade
make deps
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Review the Proposal

Before signing, review the proposal file (`proposal.json`) to understand what you are authorizing.

Verify:
- The program address being upgraded is correct
- The buffer address matches the deployed buffer
- The spill address is appropriate
- The valid-until timestamp is reasonable
- The multisig ID matches your expected multisig

### 4. Sign

Make sure your ledger is still unlocked and run the following:

```bash
make sign
```

The script will compute the hash to sign and prompt your Ledger for signature.

> [!WARNING]
> This is the most security critical part of the playbook: make sure the
> hash displayed on the Ledger screen matches the one in the terminal output.
>
> Share this hash with other signers through a trusted communication channel
> and verify it matches what they computed. If the hashes don't match,
> **DO NOT SIGN** and contact the Facilitator immediately.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```shell
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!
