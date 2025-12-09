#### Execute the transaction

## 1. Update repo:

```bash
cd contract-deployments
git pull
cd mainnet/2025-12-01-pause-bridge-base
make deps
```

### 2. Execute pause

```bash
SIGNATURES=AAABBBCCC make execute-pause
```

### 3. (When ready) Execute un-pause

```bash
SIGNATURES=AAABBBCCC make execute-unpause
```
