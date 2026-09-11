#!/bin/sh
set -eu

repo_root=${REPO_ROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}
network=${1-}

[ -n "$network" ] || {
	echo "setup-pause-task: network is required (make setup-pause-task network=<network>)" >&2
	exit 1
}
case "$network" in
	*[!A-Za-z0-9_-]*)
		echo "setup-pause-task: invalid network: $network" >&2
		exit 1
		;;
esac
[ -f "$repo_root/config/$network.env" ] || {
	echo "setup-pause-task: unsupported network: $network" >&2
	exit 1
}

task_id="$(date +%F)-pause-superchain-config"
task_dir="$repo_root/active/evm/tasks/$task_id"
config_dir="$task_dir/config/$network"

if [ -e "$task_dir" ]; then
	grep -q 'active/evm/make/superchain-pause.mk' "$task_dir/Makefile" 2>/dev/null || {
		echo "setup-pause-task: task path already exists: $task_dir" >&2
		exit 1
	}
else
	mkdir -p "$task_dir/config"

	cat >"$task_dir/Makefile" <<'EOF'
ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK must be set on the command line; run make TASK_NETWORK=<network> <target>)
endif

include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

RPC_URL := $(L1_RPC_URL)

include $(REPO_ROOT)/active/evm/make/superchain-pause.mk
EOF

	cat >"$task_dir/FACILITATOR.md" <<'EOF'
# Facilitator Guide

Guide for collecting pre-signed `SuperchainConfig.pause` transactions and executing an emergency pause.

Replace `TASK_NETWORK=<network>` in every command with the selected task network.

## 1. Collect pause signatures

Ask each incident multisig signer to follow `config/<network>/README.md`. Each signer sends `config/<network>/signatures-pause.txt`, containing signatures for 20 consecutive Safe nonces.

This task does not generate signer-tool validation JSON or use separate approval transactions. The incident multisig signatures authorize the pause directly.

## 2. Aggregate signatures

Combine every signer's entries into one comma-separated string with no spaces.

## 3. Check onchain state

```bash
make TASK_NETWORK=<network> check-status
make TASK_NETWORK=<network> check-nonce
```

## 4. Execute an emergency pause

Select the signatures matching the current incident multisig nonce, then run:

```bash
SIGNATURES=AAABBBCCC make TASK_NETWORK=<network> execute-pause
```

Verify the pause with `make TASK_NETWORK=<network> check-status`, set the signer README status to `EXECUTED`, and commit the execution records.
EOF
fi

[ ! -e "$config_dir" ] || {
	echo "setup-pause-task: network config already exists: $config_dir" >&2
	exit 1
}
mkdir -p "$config_dir"

cat >"$config_dir/.env" <<'EOF'
# Any change to this pin could break internal pauser compatibility.
# Coordinate an internal pauser update before changing it.
BASE_CONTRACTS_COMMIT=be7c7a642e430fa64b04b63203839f8c81f48466
RECORD_STATE_DIFF=true
EOF

cat >"$config_dir/README.md" <<EOF
# Pause SuperchainConfig

Status: READY TO SIGN

## Description

Pre-sign 20 transactions that pause Base through the $network incident multisig.

## Sign

Update the repository, then run:

\`\`\`bash
cd contract-deployments/active/evm/tasks/$task_id
make TASK_NETWORK=$network deps
make TASK_NETWORK=$network sign-pause
\`\`\`

Send \`config/$network/signatures-pause.txt\` to the facilitator through the approved secure channel.
EOF

echo "Created $config_dir"
echo "Next: cd active/evm/tasks/$task_id"
