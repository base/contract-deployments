#### Execute the transaction

## 1. Update repo:

```bash
cd contract-deployments
git pull
cd <network>/<task-name>
make deps
```

### 2. Check current pause status

```bash
make check-status
```

### 3. Execute pause

```bash
SIGNATURES=AAABBBCCC make execute-pause
```
