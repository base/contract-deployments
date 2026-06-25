#### Execute the transaction

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-12-04-set-jovian-parameters
make deps
```

### 2. Execute

1. Collect outputs from all participating signers.
1. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`.
1. Run the `make execute` command as described below to execute the transaction.

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

Execute the transaction:

```bash
SIGNATURES=AAAABBBBCCCC make execute
```
