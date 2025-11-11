<!-- This guide provides step-by-step instructions for creating a new deployment task -->

# How to Create a New Deployment Task

This guide walks you through creating a new Base chain deployment or upgrade task from scratch using our template system.

## Prerequisites

1. **Foundry installed**: Run `make install-foundry` from the repo root.
2. **Repository cloned**: You have a local copy of `contract-deployments`.
3. **Environment access**: You can access `.env` files (they should never be committed; use `.env.example` as reference).
4. **Git basics**: You can create branches and commit code.

## Step 1: Choose a Task Template

Depending on what you need to do, select the appropriate template:

- **Generic task** (contract calls, upgrades, one-off deployments): `template-generic`
- **Gas limit increase**: `template-gas-increase`
- **Safe owner swap**: `template-safe-management`
- **Funding from a Safe**: `template-funding`
- **Base Bridge pause/unpause**: `template-pause-bridge-base`
- **Fault proof upgrade**: `template-upgrade-fault-proofs`

## Step 2: Create the Task Directory

Use the `make` command to generate a new task folder. This will copy the selected template and create the directory structure.

### Example: Create a gas increase task on mainnet

```bash
cd /path/to/contract-deployments
make setup-gas-increase network=mainnet
# Output: creates mainnet/YYYY-MM-DD-increase-gas-limit/
```

### Example: Create a generic task on sepolia for testing

```bash
make setup-task network=sepolia task=my-test-task
# Output: creates sepolia/YYYY-MM-DD-my-test-task/
```

## Step 3: Fill in the `.env` File

Navigate to your newly created task directory and copy `.env.example` to `.env`:

```bash
cd mainnet/2025-02-12-increase-gas-limit/
cp .env.example .env
# Edit .env with your editor and fill in the placeholders
```

### Example `.env` for gas-increase task

```properties
OP_COMMIT=abc123def456...
BASE_CONTRACTS_COMMIT=def789abc123...
OLD_GAS_LIMIT=60000000
NEW_GAS_LIMIT=100000000
L1_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
```

### Critical: Never commit `.env` files

Always use `.env.example` to document required variables without exposing secrets.

## Step 4: Set Up Dependencies

Run `make deps` to fetch the Optimism and Base contracts repositories at the commits specified in `.env`:

```bash
make deps
```

This will:
1. Install Foundry dependencies (OpenZeppelin, Solmate, etc.)
2. Clone Optimism repo at the specified commit
3. Clone Base contracts repo at the specified commit

## Step 5: Write Your Script or Solidity Code

- **Solidity scripts**: Place in `script/` directory. Extend `MultisigBuilder` from base-contracts.
  - Example: `script/UpgradeSystemConfig.s.sol`
  
- **JSON inputs**: Place configuration in `inputs/` directory.
  - Example: `inputs/addresses.json`

- **Output records**: Foundry will autogenerate in `records/` after execution.

### Example Script Structure (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigBuilder, Simulator, IMulticall3} from "@base-contracts/script/universal/MultisigBuilder.sol";

contract UpgradeSystemConfig is MultisigBuilder {
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint256 internal NEW_GAS_LIMIT = vm.envUint("NEW_GAS_LIMIT");

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(SystemConfig.setGasConfig, (0, NEW_GAS_LIMIT))
        });
        return calls;
    }

    function _postCheck() internal view override {
        require(SystemConfig(L1_SYSTEM_CONFIG).gasLimit() == NEW_GAS_LIMIT, "Gas limit not updated");
    }

    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }
}
```

## Step 6: Build and Test Locally

```bash
# Build the scripts
forge build

# Optionally run local tests
forge test

# Check formatting
forge fmt --check
```

## Step 7: Generate Validation File

For multisig tasks, generate the validation file that signers will use:

```bash
make gen-validation
```

This will:
1. Run your script against a test RPC (Tenderly simulation or local fork).
2. Generate a `VALIDATION.md` file showing all state changes.
3. Output to `validations/` or root task directory (depending on template).

### Example: Manual validation file structure

If auto-generation is not available, create `VALIDATION.md`:

```markdown
# Validation for Gas Limit Increase

## Expected State Changes

1. **SystemConfig (L1_SYSTEM_CONFIG)**
   - `gasLimit()` should change from `60000000` to `100000000`
   - Safe nonce should increment by 1

## Verification Steps

1. Check Etherscan: [SystemConfig](https://etherscan.io/address/0x...) storage slot
2. Verify Safe transaction on [Safe UI](https://safe.ethereum.io/)
```

## Step 8: Commit and Push

Create a git branch and commit your changes:

```bash
git checkout -b deployment/increase-gas-limit-feb-2025
git add .
git commit -m "deployment: add gas limit increase task for Feb 2025"
git push --set-upstream origin deployment/increase-gas-limit-feb-2025
```

### Commit Message Format

```
deployment: <network>/<task-date>-<task-description>

- Increase gas limit to 100M
- Update SystemConfig
- Include validation checklist

Signed-by: <your-signer-name>
```

## Step 9: Open a Pull Request

On GitHub, open a PR with:

- **Title**: `deployment: <network>/<task> - <description>`
- **Description**: Include the validation checklist and any notes.
- **Checklist**:
  - [ ] Task directory created from template
  - [ ] `.env` file filled in (NOT committed)
  - [ ] `.env.example` documents all required variables
  - [ ] `forge build` passes locally
  - [ ] Solidity scripts have `_postCheck()` function
  - [ ] `VALIDATION.md` is complete
  - [ ] No secrets or private keys in code

## Step 10: Coordinate Signing (for Multisig Tasks)

Once the PR is merged or approved:

1. **Signers pull the branch**: Each multisig signer pulls the branch.
2. **Run signing command**: 
   ```bash
   make sign-upgrade
   # or specific signer target, e.g., make sign-op
   ```
3. **Collect signatures**: Facilitator collects all signatures.
4. **Execute**: Facilitator runs:
   ```bash
   SIGNATURES=0x... make execute
   ```
5. **Update README**: Mark task as `EXECUTED` and commit records files.

## Common Issues & Troubleshooting

### Issue: `OP_COMMIT` or `BASE_CONTRACTS_COMMIT` not set
**Solution**: Copy `.env.example` to `.env` and fill in commit hashes.

```bash
# Find recent commits:
# OP: https://github.com/ethereum-optimism/optimism/commits/develop
# Base: https://github.com/base-org/contracts/commits/main
```

### Issue: `forge build` fails with missing imports
**Solution**: Run `make deps` first.

### Issue: Script doesn't have `_postCheck()`
**Solution**: Add the `_postCheck()` function to your script (required by CI).

```solidity
function _postCheck() internal view override {
    // Add your post-execution assertions here
    require(condition, "Verification failed");
}
```

### Issue: `.env` file committed by accident
**Solution**: Remove it immediately and rebase:
```bash
git rm --cached .env
git commit -m "remove: accidentally committed .env file"
```

## Example: Complete Task Creation Workflow

```bash
# 1. Create directory
make setup-gas-increase network=mainnet
cd mainnet/2025-02-12-increase-gas-limit

# 2. Set up env
cp .env.example .env
# Edit .env with your values

# 3. Set up dependencies
make deps

# 4. Create script (edit script/IncreaseGasLimit.s.sol)

# 5. Build
forge build

# 6. Generate validation
make gen-validation

# 7. Commit
git add .
git commit -m "deployment: mainnet gas limit increase to 100M"
git push

# 8. Collect signatures
make sign-upgrade

# 9. Execute (facilitator only)
make execute
```

## More Information

- See `README.md` for general project info.
- See `CONTRIBUTING.md` for code contribution guidelines.
- See `Multisig.mk` for available Makefile targets.
- See task examples in `mainnet/` and `sepolia/` directories.

**Questions?** Open an issue on GitHub or ask in the Base Developer Discord.
