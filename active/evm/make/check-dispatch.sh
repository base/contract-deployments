#!/usr/bin/env bash
set -euo pipefail

evm_root=$(cd "$(dirname "$0")/.." && pwd)
task_id=".make-check-$$"
task_dir="$evm_root/tasks/$task_id"
trap 'rm -rf "$task_dir"' EXIT

mkdir -p "$task_dir/config/testnet"
cat > "$task_dir/config/testnet/network.env" <<'EOF'
L1_RPC_URL=http://127.0.0.1:8545
L2_RPC_URL=http://127.0.0.1:9545
LEDGER_ACCOUNT=0
EOF
cat > "$task_dir/config/testnet/.env" <<'EOF'
BASE_CONTRACTS_COMMIT=test
RECORD_STATE_DIFF=true
EOF

check() {
  local operation=$1 mode=${2:-} expected=$3
  {
    echo "OPERATION := $operation"
    echo "TASK_NETWORK ?= testnet"
    [[ -z "$mode" ]] || echo "GAS_MODE := $mode"
  } > "$task_dir/Task.mk"

  output=$(make -s -C "$evm_root" TASK_ID="$task_id" show-config)
  grep -Fq "SCRIPT_NAME=$expected" <<< "$output"
}

check funding "" script/common/funding/Fund.s.sol:FundScript
check gas gas-only script/common/gas/SetGasLimit.s.sol:SetGasLimit
check gas combined script/common/gas/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol:IncreaseEip1559ElasticityAndIncreaseGasLimitScript
check safe-management "" script/common/safe/UpdateSigners.s.sol:UpdateSigners
check bridge-threshold "" script/common/bridge/SetThreshold.s.sol:SetThreshold
check pause-bridge "" script/common/bridge/PauseBridge.s.sol:PauseBridge
check superchain-pause "" script/common/superchain/PauseSuperchainConfig.s.sol:PauseSuperchainConfig

cat > "$task_dir/Task.mk" <<'EOF'
OPERATION := custom
TASK_NETWORK ?= testnet
SCRIPT_NAME := script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership
EOF
output=$(make -s -C "$evm_root" TASK_ID="$task_id" show-config)
grep -Fq "SCRIPT_NAME=script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership" <<< "$output"

echo "active/evm Make dispatcher checks passed"
