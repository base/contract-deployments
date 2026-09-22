#!/bin/sh
set -eu

repo_root=${REPO_ROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}
network=${1-}
task_id=${2-}

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

tasks_dir="$repo_root/active/evm/tasks"
mkdir -p "$tasks_dir"

if [ -n "$task_id" ]; then
	case "$task_id" in
		.|..|*[!A-Za-z0-9._-]*)
			echo "setup-pause-task: invalid TASK_ID: $task_id" >&2
			exit 1
			;;
	esac
else
	existing_task=""
	for candidate in "$tasks_dir"/*; do
		[ -d "$candidate" ] || continue
		grep -q 'active/evm/make/pause-bridge.mk' "$candidate/Makefile" 2>/dev/null || continue
		[ -z "$existing_task" ] || {
			echo "setup-pause-task: multiple active pause tasks; rerun with TASK_ID=<task-id>" >&2
			exit 1
		}
		existing_task=$candidate
	done
	task_id=${existing_task##*/}
	[ -n "$task_id" ] || task_id="$(date +%F)-pause-bridge"
fi

task_dir="$repo_root/active/evm/tasks/$task_id"
config_dir="$task_dir/config/$network"

if [ -e "$task_dir" ]; then
	grep -q 'active/evm/make/pause-bridge.mk' "$task_dir/Makefile" 2>/dev/null || {
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

include $(REPO_ROOT)/active/evm/make/pause-bridge.mk
EOF
fi

if [ ! -e "$task_dir/FACILITATOR.md" ]; then
	cat >"$task_dir/FACILITATOR.md" <<'EOF'
# Facilitator Guide

This task collects pre-signed withdrawal pause transactions for the pauser service.

1. Ask each signer to follow `config/<network>/README.md`.
2. Collect each `config/<network>/signatures-pause.txt` through the approved secure channel.
3. Hand the signature files to the pauser-service operator for aggregation and configuration.

This task does not generate validation files, collect onchain approvals, or execute transactions manually.
EOF
fi

[ ! -e "$config_dir" ] || {
	echo "setup-pause-task: network config already exists: $config_dir" >&2
	exit 1
}
mkdir -p "$config_dir"

cat >"$config_dir/.env" <<'EOF'
# active/evm common scripts are written against base-contracts v8.3.0.
# Coordinate an internal pauser update before changing this pin.
BASE_CONTRACTS_COMMIT=385f21a41f277d287db92fffe88dca41299162ea
EOF

cat >"$config_dir/README.md" <<EOF
# Pause Base Withdrawals

Status: READY TO SIGN

## Description

Pre-sign 20 transactions that pause Base withdrawals on $network.

## Sign

Update the repository, then run:

\`\`\`bash
cd contract-deployments/active/evm/tasks/$task_id
make TASK_NETWORK=$network deps
make TASK_NETWORK=$network sign-pause
\`\`\`

Send \`config/$network/signatures-pause.txt\` through the approved secure channel for pauser-service aggregation.
EOF

echo "Created $config_dir"
echo "Next: cd active/evm/tasks/$task_id"
