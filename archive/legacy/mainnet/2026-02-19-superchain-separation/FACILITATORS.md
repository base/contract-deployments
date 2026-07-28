# Facilitator Instructions

This document describes how to execute the Superchain separation mainnet transactions after collecting signatures.

## Prerequisites

### 1. Update repo and install dependencies

```bash
cd contract-deployments
git pull
cd mainnet/2026-02-19-superchain-separation
make deps
```

## General Procedure

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export as the `SIGNATURES` environment variable:
   `export SIGNATURES="[SIGNATURE1][SIGNATURE2]..."`
3. Run the appropriate `make approve-*` command(s) for each nested Safe.
4. Run the appropriate `make execute-*` command to execute the transaction.

## Important: Execution Order

**Transactions MUST be executed in order** due to nonce dependencies:

1. CB Nested Safe: Approve UpdateProxyAdminOwnerSigners

```bash
make approve-proxyadminowner-signers-cb
```

2. SC Safe: Approve UpdateProxyAdminOwnerSigners

```bash
make approve-proxyadminowner-signers-sc
```

3. CB Parent Safe: Approve UpdateProxyAdminOwnerSigners

```bash
make approve-proxyadminowner-signers-cb-coord
```

4. OP Safe: Approve UpdateProxyAdminOwnerSigners

```bash
make approve-proxyadminowner-signers-op
```

5. ProxyAdminOwner: Execute UpdateProxyAdminOwnerSigners

```bash
make execute-proxyadminownersigners
```

6. CB Nested Safe: Approve CBSafeSigners

```bash
make approve-cbsafesigners-cb
```

7. SC Safe: Approve CBSafeSigners

```bash
make approve-cbsafesigners-sc
```

8. CB Parent Safe: Execute CBSafeSigners

```bash
make execute-cbsafesigners
```

9. CB Parent Safe: Approve UpgradeSystemConfig

```bash
make approve-systemconfig-cb
```

10. SC Safe: Approve UpgradeSystemConfig

```bash
make approve-systemconfig-sc
```

11. ProxyAdminOwner: Execute UpgradeSystemConfig

```bash
make execute-systemconfig
```

12. CB Nested Safe: Execute UpgradeFeeDisburser

```bash
make execute-feedisburser
```

13. OP CB Safe: Execute TerminateSmartEscrow

```bash
make execute-terminate-smartescrow
```

14. OP CB Safe: Approve WithdrawSmartEscrow

```bash
make approve-withdraw-smartescrow-cb
```

15. OP OP Safe: Approve WithdrawSmartEscrow

```bash
make approve-withdraw-smartescrow-op
```

16. OP Parent Safe: Execute WithdrawSmartEscrow

```bash
make execute-withdraw-smartescrow
```

17. SC Safe: Execute AddSecurityCouncilSigner

```bash
make execute-add-signer
```

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
