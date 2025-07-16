# Multisig Validation Tool - Integration Guide

This guide explains how the validation tool integrates script extraction, Tenderly API simulation, and config parsing to provide comprehensive upgrade validation.

## Overview

The validation flow consists of four main steps:

1. **Script Extraction**: Run Foundry scripts to extract simulation data
2. **Tenderly Simulation**: Use extracted data to run simulations on Tenderly
3. **Config Parsing**: Parse expected validation data from JSON config files
4. **Comparison**: Compare expected vs actual state changes and overrides

## Architecture

```
Frontend (ValidationResults)
    ↓
API Endpoint (/api/validate)
    ↓
ValidationService
    ├── Script Extraction (utils/script-extractor.ts)
    ├── Tenderly API (utils/tenderly.ts)
    └── Config Parsing (utils/parser.ts)
```

## Configuration

### Environment Variables

Create a `.env.local` file in the `tool/` directory:

```bash
# Tenderly API Configuration
TENDERLY_ACCESS=your_tenderly_api_key_here

# Optional: Custom RPC URLs
MAINNET_RPC_URL=https://mainnet.gateway.tenderly.co/your_key_here
SEPOLIA_RPC_URL=https://sepolia.gateway.tenderly.co/your_key_here
```

### Getting Tenderly API Key

1. Go to [Tenderly Dashboard](https://dashboard.tenderly.co/account/authorization)
2. Generate a new API key
3. Add it to your `.env.local` file

## Usage Flow

### 1. User Makes Selections

- User Type: `Base SC`, `Coinbase`, or `OP`
- Network: `Mainnet` or `Sepolia`
- Upgrade: Selected from dynamic list

### 2. Validation Process Starts

When user reaches the validation step, the system:

1. **Extracts Script Data**:
   ```typescript
   const extractedData = await runAndExtract({
     scriptPath: '/path/to/upgrade/folder',
     rpcUrl: 'https://sepolia.gateway.tenderly.co/...',
     scriptName: 'UpgradeSystemConfigScript',
     signature: 'sign(address[])',
     args: ['["0x6AF0674791925f767060Dd52f7fB20984E8639d8"]'],
     sender: '0xb2d9a52e76841279EF0372c534C539a4f68f8C0B'
   });
   ```

2. **Calls Tenderly API**:
   ```typescript
   const tenderlyResponse = await tenderlyClient.simulateFromExtractedData(extractedData);
   const stateChanges = tenderlyClient.parseStateChanges(tenderlyResponse);
   ```

3. **Loads Expected Data**:
   ```typescript
   const configPath = `${upgradePath}/${userType.toLowerCase()}.json`;
   const parsedConfig = ConfigParser.parseFromString(configContent);
   ```

4. **Compares Results**:
   - State changes (before/after values)
   - State overrides (storage slot modifications)
   - Contract addresses and descriptions

## Config File Format

Expected validation data should be stored in JSON files following this format:

```json
{
  "task_name": "mainnet-upgrade-system-config",
  "simulation_command": "make sign --signer=base-nested",
  "expected_domain_and_message_hashes": {
    "address": "0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110",
    "domain_hash": "0x88aac3dc27cc1618ec43a87b3df21482acd24d172027ba3fbb5a5e625d895a0b",
    "message_hash": "0x9ef8cce91c002602265fd0d330b1295dc002966e87cd9dc90e2a76efef2517dc"
  },
  "expected_nested_hash": "",
  "state_overrides": [
    {
      "name": "Base Multisig",
      "address": "0x9855054731540A48b28990B63DcF4f33d8AE46A1",
      "overrides": [
        {
          "key": "0x0000000000000000000000000000000000000000000000000000000000000004",
          "value": "0x0000000000000000000000000000000000000000000000000000000000000001",
          "description": "Override the threshold to 1 so the transaction simulation can occur"
        }
      ]
    }
  ],
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
}
```

## File Structure

For each upgrade, create config files based on user type:

```
mainnet/
└── 2025-06-04-upgrade-system-config/
    ├── base-sc.json          # Base SC validation config
    ├── base-nested.json      # Coinbase validation config
    ├── op.json              # OP validation config
    └── script/
        └── UpgradeSystemConfig.s.sol
└── sepolia/
    └── 2025-06-04-upgrade-system-config/
        ├── base-sc.json
        ├── base-nested.json
        ├── op.json
        └── script/
            └── UpgradeSystemConfig.s.sol
```

## Script Parameters

The validation service automatically determines script parameters based on user type:

- **Base SC**: Uses specific signer addresses for Base Smart Contract operations
- **Coinbase**: Uses Coinbase-specific multisig addresses
- **OP**: Uses Optimism-specific signer configurations

## Error Handling

The system handles various error scenarios:

1. **Missing Config Files**: Shows warning and continues with empty expected data
2. **Script Execution Failures**: Shows detailed error messages
3. **Tenderly API Errors**: Allows user to input API key and retry
4. **Network Issues**: Provides retry options

## Debugging

The validation results page includes a debug section showing:

- Number of extracted hashes
- Simulation link status
- Tenderly simulation status
- Count of expected vs actual state changes/overrides

## Development

To test the integration locally:

1. Ensure you have valid config files in the upgrade directories
2. Add your Tenderly API key to `.env.local`
3. Run the development server: `npm run dev`
4. Navigate through the validation flow

## Troubleshooting

### Common Issues

1. **"No simulation link found"**: Check that the Foundry script is generating the expected output format
2. **"Tenderly API error"**: Verify your API key and network connectivity
3. **"Config file not found"**: Ensure config files exist with correct naming convention
4. **"No changes found"**: Verify that config files contain state_changes or state_overrides arrays

### Logs

Check the browser console and server logs for detailed error information during validation.
