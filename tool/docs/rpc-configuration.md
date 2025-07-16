# RPC URL Configuration

The validation tool determines which RPC URL to use for running Foundry scripts based on the following priority:

## Priority Order

1. **Custom RPC URL** - If provided via API request (`options.rpcUrl`)
2. **Environment File** - From `.env` file in the upgrade folder
3. **Default URLs** - Hardcoded Tenderly Gateway URLs

## Environment File Configuration

Each network folder should contain a `.env` file with the following format:

```bash
L1_RPC_URL=https://your-rpc-endpoint.com
```

The tool will automatically read this file and use the `L1_RPC_URL` value when running scripts for any upgrade in that network.

### File Location
```
mainnet/
├── .env                          # RPC URL configuration for all mainnet upgrades
├── 2025-06-04-upgrade-system-config/
├── 2025-04-23-upgrade-fault-proofs/
└── ...

sepolia/
├── .env                          # RPC URL configuration for all sepolia upgrades
├── 2025-06-04-upgrade-system-config/
├── 2025-05-08-update-fee-disperser-ownership/
└── ...
```

### Supported Formats
- `L1_RPC_URL=https://rpc.example.com`
- `L1_RPC_URL="https://rpc.example.com"` (with quotes)
- `L1_RPC_URL='https://rpc.example.com'` (with single quotes)

## Default RPC URLs

If no custom RPC URL is provided and no `.env` file is found, the following defaults are used:

- **Mainnet**: `https://mainnet.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul`
- **Sepolia**: `https://sepolia.gateway.tenderly.co/3e5npc9mkiZ2c2ogxNSGul`

## API Usage

To override the RPC URL via API:

```typescript
// Currently not implemented in API, but ValidationOptions supports it:
{
  "upgradeId": "2025-06-04-upgrade-system-config",
  "network": "sepolia",
  "userType": "Coinbase",
  "rpcUrl": "https://custom-rpc.example.com"  // Optional override
}
```

## Debugging

The tool logs which RPC URL source is being used:

- `📡 Using RPC URL from mainnet/.env file: https://...` - When using mainnet .env file
- `📡 Using RPC URL from sepolia/.env file: https://...` - When using sepolia .env file
- `📡 Using default RPC URL: https://...` - When using defaults
- `⚠️ Failed to read .env file: ...` - When .env file exists but can't be read
