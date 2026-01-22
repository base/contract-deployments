# Generic Multisig Script Template

Status: TEMPLATE

## Description

This is the base template for creating new multisig operations. It provides a starting point with the standard file structure and Makefile targets needed for signing and executing transactions via Gnosis Safe multisigs.

Use this template when you need to create a new task that doesn't fit one of the specialized templates (gas increase, fault proof upgrade, etc.).

## Setup

### 1. Create a new task directory

From the repository root:

```bash
make setup-task network=<network> task=<task-name>
```

This copies the template to `<network>/<date>-<task-name>/`.

### 2. Install dependencies

```bash
cd <network>/<date>-<task-name>
make deps
```

### 3. Configure environment

Edit `.env` and set all required variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `OP_COMMIT` | Yes | Git commit hash for ethereum-optimism/optimism |
| `BASE_CONTRACTS_COMMIT` | Yes | Git commit hash for base/contracts |
| `TARGET` | Yes | Target contract address for the operation |
| `OWNER_SAFE` | Yes | Top-level Gnosis Safe address |
| `L1_0`, `L1_1` | Depends | First-level nested safe addresses (if using nested safes) |
| `L2_0`, `L2_1` | Depends | Second-level nested safe addresses (if using nested safes) |

### 4. Validate configuration

```bash
make validate-config
```

### 5. Implement your script

Edit `script/BasicScript.s.sol` or `script/CounterMultisigScript.s.sol` to implement your specific operation. The script should:

1. Read configuration from environment variables in the constructor
2. Implement `_buildCalls()` to return the multicall operations
3. Implement `_postCheck()` to validate the transaction succeeded
4. Implement `_ownerSafe()` to return the safe address

## Safe Hierarchy

This template supports nested safe structures for multi-party signing:

```
OWNER_SAFE/
├── L1_0/
│   ├── L2_0/
│   │   └── Signers
│   └── L2_1/
│       └── Signers
└── L1_1/
    └── Signers
```

## Signing Flow

### For signers at L2_0:
```bash
make sign-l2-0
```

### For signers at L2_1:
```bash
make sign-l2-1
```

### For signers at L1_1:
```bash
make sign-l1-1
```

### For approving nested safes:
```bash
SIGNATURES=<collected-signatures> make approve-l2-0
SIGNATURES=<collected-signatures> make approve-l2-1
SIGNATURES=<collected-signatures> make approve-l1-0
SIGNATURES=<collected-signatures> make approve-l1-1
```

### Final execution:
```bash
make execute
```

## Ledger Setup

Your Ledger needs to be connected and unlocked. The Ethereum application needs to be opened on Ledger with the message "Application is ready".

To use a different Ledger account index:
```bash
LEDGER_ACCOUNT=1 make sign-l2-0
```