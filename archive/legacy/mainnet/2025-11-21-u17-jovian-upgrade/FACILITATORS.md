#### Execute the transaction

## 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-11-21-u17-jovian-upgrade
make deps
```

1. IMPORTANT: Ensure op-challenger has been updated before executing.
1. Collect outputs from all participating signers.
1. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`.
1. Run the `make execute` or `make approve` command as described below to execute the transaction.

For example, if the quorum is 3 and you get the following outputs:

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE03
Signature: CCCC
```

Coinbase facilitator:

```bash
SIGNATURES=AAAABBBBCCCC make approve-cb
```

```bash
SIGNATURES=AAAABBBBCCCC make approve-cb-sc
```

Optimism facilitator:

```bash
SIGNATURES=AAAABBBBCCCC make approve-op
```

Once the signatures have been submitted approving the transaction for all nested Safes run:

```bash
make execute
```
