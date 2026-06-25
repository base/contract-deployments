# Facilitator Guide

Guide for facilitators after collecting signatures from signers. For sepolia tasks, the facilitator only needs to collect signatures for the base nested safe.

### 1. Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2025-10-09-fusaka-defense
make deps
```

### 2. Approve base nested safe

```bash
SIGNATURES=AAABBBCCC make approve-cb
```

### 3. Sign for mock SC

### 4. Approve for mock SC

```bash
SIGNATURES=AAABBBCCC make approve-cb-sc
```

### 5. Sign for mock OP

### 6. Approve for mock OP

```bash
SIGNATURES=AAAABBBBCCCC make approve-op
```

### 7. Approve for CB coordinator

```bash
make approve-coordinator
```

### 8. Execute

```bash
make execute
```
