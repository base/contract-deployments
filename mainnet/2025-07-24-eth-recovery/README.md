# ETH Recovery Analysis & Execution

This directory contains the complete ETH recovery system that analyzes blockchain transactions to identify addresses eligible for ETH recovery and executes the recovery process across multiple chains.

## Overview

The system works in two phases:
1. **Analysis Phase**: Analyzes blockchain transactions to identify eligible addresses
2. **Execution Phase**: Executes recovery scripts using the analyzed data

## Supported Chains

- **Arbitrum One** (Chain ID: 42161)
- **Base** (Chain ID: 8453)  
- **Optimism** (Chain ID: 10)

## Setup

### 1. Install Dependencies

```bash
# Install TypeScript dependencies for analysis
make install-analysis-deps
```

### 2. Configure Environment

Copy the environment template and add your API keys:

```bash
cp .env.example .env
```

Edit `.env` and add:
- `ETHERSCAN_API_KEY`: Required for fetching transaction data
- `NAUGHTY_LIST_API_KEY`: Optional for address filtering
- `NODE_ENV`: Set to `development` for dev endpoints (optional)

## Usage

### Analysis Commands

Run analysis for individual chains:

```bash
# Analyze Arbitrum addresses
make analyze-arbitrum

# Analyze Base addresses  
make analyze-base

# Analyze Optimism addresses
make analyze-optimism

# Analyze all chains at once
make analyze-all
```

**Note**: Analysis can take 10-30 minutes per chain depending on transaction volume and API rate limits.

### Recovery Execution Commands

Execute recovery for individual chains (requires RPC_URL):

```bash
# Execute Arbitrum recovery
make execute-arbitrum-recovery RPC_URL=https://arb1.arbitrum.io/rpc

# Execute Base recovery
make execute-base-recovery RPC_URL=https://mainnet.base.org

# Execute Optimism recovery  
make execute-optimism-recovery RPC_URL=https://mainnet.optimism.io
```

### Dry Run Commands

Test recovery scripts without broadcasting:

```bash
# Dry run Arbitrum recovery
make dry-run-arbitrum-recovery RPC_URL=https://arb1.arbitrum.io/rpc

# Dry run Base recovery
make dry-run-base-recovery RPC_URL=https://mainnet.base.org

# Dry run Optimism recovery
make dry-run-optimism-recovery RPC_URL=https://mainnet.optimism.io
```

## How It Works

### Analysis Process

1. **Transaction Fetching**: Retrieves all incoming ETH transactions to the target address within specified block ranges
2. **Address Categorization**: Categorizes senders as:
   - **CEX**: Known centralized exchange addresses (excluded from recovery)
   - **NAUGHTY**: Addresses flagged by compliance systems (excluded from recovery)  
   - **NORMAL**: Regular addresses eligible for recovery
3. **Address Type Detection**: Identifies whether addresses are EOAs or smart contracts
4. **Output Generation**: Creates recovery files in Solidity-compatible format

### Recovery Process

1. **Prerequisites Check**: Verifies that analysis has been completed
2. **Data Loading**: Loads recovery addresses from analysis output
3. **Cross-chain Execution**: Submits recovery transactions to L2s via L1 portals:
   - **Arbitrum**: Uses delayed inbox for L1→L2 messaging
   - **Base**: Uses OptimismPortal2 for deposits
   - **Optimism**: Uses OptimismPortal2 for deposits

## File Structure

```
mainnet/2025-07-24-eth-recovery/
├── src/
│   ├── analyze.ts              # Main analysis script
│   ├── types/index.ts          # TypeScript type definitions
│   └── config/
│       ├── settings.ts         # Chain and API configurations
│       └── cex-wallets.json    # Known CEX addresses
├── script/
│   ├── ArbitrumExecuteRecovery.s.sol   # Arbitrum recovery script
│   ├── BaseExecuteRecovery.s.sol       # Base recovery script
│   └── OptimismExecuteRecovery.s.sol   # Optimism recovery script
├── output/
│   ├── arbitrum/
│   │   └── recovery_addresses.json     # Arbitrum recovery data (generated)
│   ├── base/
│   │   └── recovery_addresses.json     # Base recovery data (generated)
│   └── optimism/
│       └── recovery_addresses.json     # Optimism recovery data (generated)
├── package.json                # Node.js dependencies
├── tsconfig.json              # TypeScript configuration
├── Makefile                   # Build and execution commands
└── README.md                  # This file
```

## Recovery File Format

The analysis generates JSON files in the format expected by Solidity scripts:

```json
{
  "addresses": [
    {
      "refund_address": "0x1234...5678",
      "category": "NORMAL",
      "total_eth": "1000000000000000000"
    }
  ]
}
```

Where:
- `refund_address`: Ethereum address to receive recovered ETH
- `category`: Address category (only NORMAL addresses are included)
- `total_eth`: Amount in wei (string format for precision)

## Safety Features

- **Dry Run Support**: Test execution without broadcasting transactions
- **Address Filtering**: Excludes CEX and flagged addresses from recovery
- **Prerequisite Checks**: Verifies analysis completion before execution
- **Idempotent Analysis**: Skips re-analysis if results already exist

## Troubleshooting

### Common Issues

1. **Missing API Keys**: Ensure `ETHERSCAN_API_KEY` is set in `.env`
2. **Rate Limiting**: Analysis includes built-in rate limiting, but may take time
3. **Missing Dependencies**: Run `make install-analysis-deps` first
4. **No Recovery File**: Run analysis commands before execution commands

### Getting Help

```bash
# Display all available commands
make help
```

### Manual Analysis

You can also run analysis manually:

```bash
# Analyze specific chain
npx tsx src/analyze.ts 42161  # Arbitrum
npx tsx src/analyze.ts 8453   # Base  
npx tsx src/analyze.ts 10     # Optimism
```

## Security Considerations

- Recovery files contain only addresses categorized as "NORMAL"
- CEX addresses are automatically excluded to prevent complications
- Naughty-list integration helps exclude flagged addresses
- All execution commands require explicit RPC URL specification
- Ledger hardware wallet integration for secure signing
