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
    "task_name": "your-task-name",
    "script_name": "YourScript.s.sol",
    "signature": "run(address,uint256)",
    "args": "[\"0x123...\", 1000000]",
    "expected_domain_and_message_hashes": {
      "address": "0x...",
      "domain_hash": "0x...",
      "message_hash": "0x..."
    },
    "expected_nested_hash": "",
    "state_overrides": [...],
    "state_changes": [...]
}
```
These files can be generated using our [`state-diff`](https://github.com/jackchuma/state-diff) tool.

Developer can call the tool directly on the Foundry script and valid config file will be outputed. The script will includes 

Please put in mind that correct signature and corresponding arguments is also needed for a running file.

```json
{
    "script_name": "UpgradeContract.s.sol",
    "signature": "run(address,address,bytes)",
    "args": "[\"0xProxyAddress\", \"0xNewImplementation\", \"0x\"]"
}
```
