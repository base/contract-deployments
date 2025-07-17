# Config File Examples

This document provides examples of validation config files for different types of operations.

## With Arguments

Example from a system config upgrade that requires signer addresses:

```json
{
    "task_name": "sepolia-upgrade-system-config",
    "script_name": "UpgradeSystemConfigScript",
    "signature": "sign(address[])",
    "args": "[0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f,0x646132A1667ca7aD00d36616AFBA1A28116C770A]",
    "expected_domain_and_message_hashes": {
        "address": "0x6AF0674791925f767060Dd52f7fB20984E8639d8",
        "domain_hash": "0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23",
        "message_hash": "0xf118d3927d9544e9ac00951c9e0ae5a010e8cc924e290c96de96975354f79572"
    },
    "expected_nested_hash": "",
    "state_overrides": [...],
    "state_changes": [...]
}
```

## Without Arguments

Example from a safe swap owner operation that doesn't require arguments:

```json
{
    "task_name": "mainnet-safe-swap-owner",
    "script_name": "SwapOwner",
    "signature": "sign()",
    "args": "",
    "expected_domain_and_message_hashes": {
        "address": "0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110",
        "domain_hash": "0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac",
        "message_hash": "0xf1160d2510c49ad09ba91899c9584a87bf4292a5272a2751796281a91cb8b9b4"
    },
    "expected_nested_hash": "",
    "state_overrides": [...],
    "state_changes": [...]
}
```

## Key Differences

1. **Signature**:
   - With args: `"signature": "sign(address[])"`
   - Without args: `"signature": "sign()"`

2. **Args field**:
   - With args: `"args": "[0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f,0x646132A1667ca7aD00d36616AFBA1A28116C770A]"`
   - Without args: `"args": ""`

## Script Parameters

The validation service uses these fields to construct the forge command:

- **script_name**: The Solidity contract name (without .s.sol extension)
- **signature**: The function signature to call
- **args**: Arguments to pass to the function (can be empty string)

### Resulting Commands

With arguments:
```bash
forge script --rpc-url <RPC_URL> UpgradeSystemConfigScript --sig "sign(address[])" [0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f,0x646132A1667ca7aD00d36616AFBA1A28116C770A] --sender <SENDER>
```

Without arguments:
```bash
forge script --rpc-url <RPC_URL> SwapOwner --sig "sign()" --sender <SENDER>
```
