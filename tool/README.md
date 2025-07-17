# Multisig Validation Tool

A CLI tool for verifying Base ops tasks against expected state changes using Tenderly simulations.

## Overview

This tool helps validate multisig operations by:

1. Reading task configuration files that define expected state changes
2. Executing simulation commands (typically Forge scripts)
3. Extracting Tenderly simulation URLs from command output
4. Fetching actual state changes from Tenderly API
5. Comparing expected vs actual state changes
6. Providing detailed verification reports

## Prerequisites

- **Node.js** 18+ and npm
- **Foundry/Forge** (for running simulation commands)
- **Tenderly account** (for accessing simulation data)
- Access to **deployment configurations** in the repository

## Quick Start

1. **Clone and install:**

   ```bash
   git clone <repository-url>
   cd multisig-validation-tool
   npm install
   ```

2. **Run a verification:**
   ```bash
   npm run dev --workspace=cli -- verify upgrade-proxy-admin --signer coinbase
   ```

## Installation

### Development Setup

```bash
# Install dependencies
npm install

# Build the CLI
npm run build --workspace=cli

# Run in development mode
npm run dev --workspace=cli
```

### Global Installation

```bash
# Build and link globally
npm run build --workspace=cli
npm link --workspace=cli

# Now you can use the CLI globally
multisig-verify --help
```

## Usage

### Basic Commands

```bash
# Verify a specific task
multisig-verify verify <task-name> [options]

# List all available tasks
multisig-verify list [options]

# Get help
multisig-verify --help
multisig-verify verify --help
```

### Options

| Option                | Description                                       | Default           |
| --------------------- | ------------------------------------------------- | ----------------- |
| `-s, --signer <type>` | Signer type: `coinbase`, `optimism`, or `default` | `default`         |
| `-p, --path <path>`   | Path to deployment configurations                  | Current directory |
