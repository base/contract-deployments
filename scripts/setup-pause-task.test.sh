#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d /tmp/setup-pause-task.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config" "$tmp/active/evm/tasks"
cp "$repo_root/Makefile" "$repo_root/Multisig.mk" "$tmp/"
: >"$tmp/config/mainnet.env"
: >"$tmp/config/sepolia.env"

REPO_ROOT="$tmp" "$repo_root/scripts/setup-pause-task.sh" mainnet >/dev/null
task="$tmp/active/evm/tasks/$(date +%F)-pause-superchain-config"
test -f "$task/Makefile"
test -f "$task/FACILITATOR.md"
test -f "$task/config/mainnet/.env"
grep -q 'make TASK_NETWORK=mainnet sign-pause' "$task/config/mainnet/README.md"
make -s -C "$task" TASK_NETWORK=mainnet -n check-nonce >/dev/null

if make -s -C "$task" -n check-nonce >/dev/null 2>&1; then
	echo "setup-pause-task test: TASK_NETWORK should be required" >&2
	exit 1
fi

if TASK_NETWORK=mainnet make -s -C "$task" -n check-nonce >/dev/null 2>&1; then
	echo "setup-pause-task test: exported TASK_NETWORK should be rejected" >&2
	exit 1
fi

REPO_ROOT="$tmp" "$repo_root/scripts/setup-pause-task.sh" sepolia >/dev/null
test -f "$task/config/sepolia/README.md"

if REPO_ROOT="$tmp" "$repo_root/scripts/setup-pause-task.sh" mainnet >/dev/null 2>&1; then
	echo "setup-pause-task test: duplicate network should fail" >&2
	exit 1
fi

echo "setup-pause-task test: ok"
