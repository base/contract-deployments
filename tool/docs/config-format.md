# Multisig Validation Tool - Configuration Format

This document describes the JSON configuration format for multisig task validation.

## Overview

The configuration file defines:

- **Simulation command** to execute for the task
- **Expected domain/message hashes** for ledger verification
- **Expected state changes** that should occur during execution
- **State overrides** needed for simulation to work properly

## Configuration Structure

```json
{
  "task_name": "string",
  "simulation_command": "string",
  "expected_domain_and_message_hashes": {
    "address": "string",
    "domain_hash": "string",
    "message_hash": "string"
  },
  "expected_nested_hash": "string",
  "state_overrides": [...],
  "state_changes": [...]
}
```

## Fields Reference

### `task_name`

**Type**: `string`  
**Description**: Unique identifier for the multisig task

```json
"task_name": "mainnet-dispute-game-factory-upgrade"
```

### `simulation_command`

**Type**: `string`  
**Description**: The command to execute for running the simulation

```json
"simulation_command": "make sign --signer=base-nested"
```

### `expected_domain_and_message_hashes`

**Type**: `object`  
**Description**: Expected EIP-712 domain and message hashes for ledger verification before signing

**Properties**:

- `address`: The multisig contract address that will be signing
- `domain_hash`: Expected EIP-712 domain separator hash
- `message_hash`: Expected EIP-712 message hash

```json
"expected_domain_and_message_hashes": {
  "address": "0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd",
  "domain_hash": "0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3",
  "message_hash": "0x0693f70caf333f60a20ad8e44b451bd4cea3d2703016c277d5b0d09ecd3c3638"
}
```

### `expected_nested_hash`

**Type**: `string`  
**Description**: Expected hash for nested multisig transactions (if applicable)

```json
"expected_nested_hash": ""
```

### `state_overrides`

**Type**: `array`  
**Description**: Storage slot overrides needed to make the simulation succeed

Each override object contains:

- `name`: Human-readable name for the contract
- `address`: Contract address to override
- `overrides`: Array of storage slot overrides

```json
"state_overrides": [
  {
    "name": "ProxyAdminOwner",
    "address": "0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c",
    "overrides": [
      {
        "key": "0x0000000000000000000000000000000000000000000000000000000000000004",
        "value": "0x0000000000000000000000000000000000000000000000000000000000000001",
        "description": "Override the threshold to 1 so the transaction simulation can occur"
      }
    ]
  }
]
```

#### Override Object Structure

```json
{
  "key": "0x...", // Storage slot to override (32-byte hex)
  "value": "0x...", // Value to set in that slot (32-byte hex)
  "description": "string" // Human-readable explanation
}
```

**Common Override Patterns**:

- **Threshold Override**: Set multisig threshold to 1 (slot `0x4`)
- **Owner Count Override**: Set owner count to 1 (slot `0x3`)
- **Approval Simulation**: Set approval hash to 1 for msg.sender

### `state_changes`

**Type**: `array`  
**Description**: Expected storage changes that should occur during transaction execution

Each state change object contains:

- `name`: Human-readable name for the contract
- `address`: Contract address where changes occur
- `changes`: Array of expected storage changes

```json
"state_changes": [
  {
    "name": "System Config",
    "address": "0x73a79Fab69143498Ed3712e519A88a918e1f4072",
    "changes": [
      {
        "key": "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc",
        "before": "0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647",
        "after": "0x00000000000000000000000078ffe9209dff6fe1c9b6f3efdf996bee60346d0e",
        "description": "Updates the System Config implementation address"
      }
    ]
  }
]
```

#### Change Object Structure

```json
{
  "key": "0x...", // Storage slot that changes (32-byte hex)
  "before": "0x...", // Expected value before transaction (32-byte hex)
  "after": "0x...", // Expected value after transaction (32-byte hex)
  "description": "string" // Human-readable explanation of the change
}
```

**Common Change Patterns**:

- **Nonce Increment**: Multisig nonce increases by 1 (slot `0x5`)
- **Approval Hash**: Sets approval hash to 1 for specific transaction
