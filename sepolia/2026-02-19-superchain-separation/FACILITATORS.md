# Facilitator Instructions

This document describes how to execute the Superchain separation sepolia transactions after collecting signatures.

## Prerequisites

### 1. Update repo and install dependencies

```bash
cd contract-deployments
git pull
cd sepolia/2026-02-19-superchain-separation
make deps
```

## General Procedure

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export as the `SIGNATURES` environment variable:
   `export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`
3. Run the appropriate `make approve-*` command(s) for each nested Safe.
4. Run the appropriate `make execute-*` command to execute the transaction.

## Important: Execution Order

**Transactions MUST be executed in order (Part 1 → Part 2 → Part 3)** due to nonce dependencies:

1. CB Nested Safe: Approve CBSafeSigners
2. SC Safe: Approve CBSafeSigners
3. CB Parent Safe: Execute CBSafeSigners
4. CB Parent Safe: Approve UpgradeSystemConfig
5. SC Safe: Approve UpgradeSystemConfig
6. ProxyAdminOwner: Execute UpgradeSystemConfig
7. CB Nested Safe: Execute UpgradeFeeDisburser

### Example Signature Output

If the quorum is 3 and you receive the following outputs:

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

Concatenate: `SIGNATURES=AAAABBBBCCCC`

---

## Part 1: UpdateCBSafeSigners (CB + SC)

Updates the signers on the Coinbase Safe.

### Approve

Coinbase facilitator (with CB signer signatures):

```bash
SIGNATURES=<CB_SIGNATURES> make approve-cbsafesigners-cb
```

Coinbase facilitator (with SC signer signatures):

```bash
SIGNATURES=<SC_SIGNATURES> make approve-cbsafesigners-sc
```

### Execute

Once all approvals are submitted:

```bash
make execute-cbsafesigners
```

---

## Part 2: UpgradeSystemConfig (CB + SC)

Upgrades the SystemConfig contract with the new SuperchainConfig.

### Approve

Coinbase facilitator (with CB signer signatures):

```bash
SIGNATURES=<CB_SIGNATURES> make approve-systemconfig-cb
```

Coinbase facilitator (with SC signer signatures):

```bash
SIGNATURES=<SC_SIGNATURES> make approve-systemconfig-sc
```

### Execute

Once all approvals are submitted:

```bash
make execute-systemconfig
```

---

## Part 3: UpgradeFeeDisburser (CB only)

Upgrades the FeeDisburser contract via a deposit transaction on L1.

> **Note:** This must be executed AFTER Part 1 (execute-cbsafesigners) due to nonce dependencies on `CB_NESTED_SAFE_ADDR`.

### Approve (if using nested safe)

```bash
SIGNATURES=<CB_SIGNATURES> make approve-feedisburser
```

### Execute

```bash
SIGNATURES=<CB_SIGNATURES> make execute-feedisburser
```
