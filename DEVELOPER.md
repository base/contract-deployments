# Valid Setup for Upgrade folder! 🚀

This guide will walk you through setting up a correct upgrade folder so that it is compatible for validation tool. 

## Structure
1. `script` folder that contains Foundry script for deployment / upgrade.
2. `validations` folder that contains validation files in json format
3. `README.md` file that contains information about the upgrade name and status


## Setup Validation File

Create validation JSON files for each signer role using the `validation-format.json` template.

### Required Files by Role:
- `base-nested.json` - For base nested safe signers
- `base-sc.json` - For base smart contract signers  
- `op.json` - For OP signers

### Basic Structure:
```json
{
  "task_name": "chain-task-name",
  "script_name": "script-name",
  "signature": "script-signature()",
  "args": "[script-args]",
  "ledger-id": 0,
  "expected_domain_and_message_hashes": {
    "address": "address-of-the-contract",
    "domain_hash": "domain-hash",
    "message_hash": "message-hash"
  },
  "expected_nested_hash": "",
  "state_overrides": [
    {
      "name": "name",
      "address": "address",
      "overrides": [
        {
          "key": "key",
          "value": "value",
          "description": "description"
        },
        {
          "key": "key",
          "value": "value",
          "description": "Difference is expected: [reason]"
        }
      ]
    }
  ],
  "state_changes": [
    {
      "name": "name",
      "address": "address",
      "changes": [
        {
          "key": "key",
          "before": "before",
          "after": "after",
          "description": "description"
        },
        {
          "key": "key",
          "before": "before",
          "after": "after",
          "description": "description"
        }
      ]
    },
    {
      "name": "name",
      "address": "address",
      "changes": [
        {
          "key": "key",
          "before": "before",
          "after": "after",
          "description": "description"
        }
      ]
    }
  ]
}
  
```
This file can be generated using a tool called `state-diff`, can be installed [here]((https://github.com/jackchuma/state-diff)).

Developer can call the tool directly on the Foundry script which will output a config file.

You will then need to add the function signature and corresponding arguments for the Foundry script.

1. **Function Signature**:
   - With args: `"signature": "sign(address[])"`
   - Without args: `"signature": "sign()"`

2. **Args field**:
   - With args: `"args": "[0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f,0x646132A1667ca7aD00d36616AFBA1A28116C770A]"`
   - Without args: `"args": ""`
