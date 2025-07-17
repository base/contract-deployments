# Folder Format Issues

This document outlines the various format inconsistencies found in the contract deployment README files that cause parsing issues in our multisig validation tool.

## Current Parser Implementation

Our current regex pattern for extracting executed transaction links:
```javascript
/Status:\s*EXECUTED\s*\(([^)]+)\)/
```

This pattern expects the format: `Status: EXECUTED (https://...)`

## Format Issues Found

### 1. Missing Parentheses

**Expected Format:**
```
Status: EXECUTED (https://sepolia.etherscan.io/tx/0x...)
```

**Problematic Format:**
```
Status: EXECUTED https://sepolia.etherscan.io/tx/0x...
```

**Affected Files:**
- `sepolia/2025-03-14-mirror-mainnet-hierarchy/README.md`
- `sepolia/2025-03-12-upgrade-fault-proofs/README.md`

### 2. Markdown Link Format

**Expected Format:**
```
Status: EXECUTED (https://etherscan.io/tx/0x...)
```

**Problematic Format:**
```
Status: [EXECUTED](https://etherscan.io/tx/0x...)
```

**Affected Files:**
- `mainnet/2025-05-15-eip1559-denominator-reduction/README.md`

### 3. Multi-line Format with Multiple Transactions

**Expected Format:**
```
Status: EXECUTED (https://sepolia.etherscan.io/tx/0x...)
```

**Problematic Format:**
```
Status: EXECUTED

Safe A: https://sepolia.etherscan.io/tx/0x6bc215bc3c7e609ebfcda87b3b74d433e45f685101733982b8a910331acd609b
Safe B: https://sepolia.etherscan.io/tx/0x5a3e78badcccd6e586c541c15cc2b2517dfd54ea156bf50b662b21fedf5e3a81
```

**Affected Files:**
- `sepolia/2025-04-09-testnet-multisig-signers/README.md`

### 4. Non-Executed Status (Correctly Handled)

**Format:**
```
Status: READY TO SIGN
```

This correctly doesn't match our parser and shows no execution link.

**Example Files:**
- `mainnet/2025-04-23-upgrade-fault-proofs/README.md`

## Proposed Solutions

### 1. Enhanced Regex Patterns

Create multiple regex patterns to handle different formats:

```javascript
// Pattern 1: Standard format with parentheses
/Status:\s*EXECUTED\s*\(([^)]+)\)/

// Pattern 2: Format without parentheses
/Status:\s*EXECUTED\s+(https?:\/\/[^\s]+)/

// Pattern 3: Markdown link format
/Status:\s*\[EXECUTED\]\(([^)]+)\)/

// Pattern 4: Multi-line format
/Status:\s*EXECUTED[\s\S]*?(?:Safe [A-Z]|Transaction):\s*(https?:\/\/[^\s]+)/g
```

### 2. Multiple Link Handling

For deployments with multiple transaction links:
- Parse all available transaction links
- Display them in a dropdown/hover menu
- Allow users to select which transaction to view
- Label each link appropriately (e.g., "Safe A", "Safe B", "Transaction 1", etc.)

### 3. Fallback Parsing

Implement a cascading approach:
1. Try standard format first
2. Fall back to alternative formats
3. Extract multiple links when available
4. Provide user-friendly labels for each link

## Implementation Priority

1. **High Priority**: Fix missing parentheses format (affects 2 files)
2. **High Priority**: Handle markdown link format (affects 1 file)
3. **Medium Priority**: Support multi-line multiple transactions (affects 1 file)
4. **Low Priority**: Add validation for consistent formatting across all deployments

## Testing Files

Use these specific files to test the enhanced parsing:

**Sepolia:**
- `2025-04-14-upgrade-fault-proofs` ✅ (Works with current parser)
- `2025-04-01-nested-ownership-transfer` ✅ (Works with current parser)
- `2025-03-14-mirror-mainnet-hierarchy` ❌ (Missing parentheses)
- `2025-03-12-upgrade-fault-proofs` ❌ (Missing parentheses)
- `2025-04-09-testnet-multisig-signers` ❌ (Multi-line format)

**Mainnet:**
- `2025-05-13-incident-multisig-signers` ✅ (Works with current parser)
- `2025-05-15-eip1559-denominator-reduction` ❌ (Markdown format)
- `2025-04-23-upgrade-fault-proofs` ✅ (Correctly shows no link - not executed)
