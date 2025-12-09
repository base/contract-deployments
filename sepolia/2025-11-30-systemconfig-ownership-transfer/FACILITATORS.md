#### Execute the transaction

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

Coinbase facilitator (mock):

```bash
SIGNATURES=AAAABBBBCCCC make approve-cb
```

```bash
SIGNATURES=AAAABBBBCCCC make approve-cb-sc
```

```bash
make approve-cb-coordinator
```

Optimism facilitator (mock):

```bash
SIGNATURES=AAAABBBBCCCC make approve-op
```

Since mock Safes are used in this Sepolia task, the same facilitator is expected handle gathering signatures for both the SC and OP from the same signer set.

Once the signatures have been submitted approving the transaction for all nested Safes run:

```bash
make execute
```
