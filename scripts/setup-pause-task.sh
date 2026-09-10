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
	grep -q 'script/common/superchain/PauseSuperchainConfig.s.sol' "$task_dir/Makefile" 2>/dev/null || {
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
SCRIPT_NAME := script/common/superchain/PauseSuperchainConfig.s.sol:PauseSuperchainConfig
PAUSE_ENV := RECORD_STATE_DIFF=$(RECORD_STATE_DIFF) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG)

ZERO_ADDRESS := 0x0000000000000000000000000000000000000000
SAFE_TX_TYPEHASH := 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
SAFE_TX_ABI := f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)

.PHONY: sign-pause
sign-pause:
	@test -x "$(GOPATH)/bin/eip712sign" || { echo "run make TASK_NETWORK=$(TASK_NETWORK) deps first"; exit 1; }
	@set -eu; \
	output=signatures-pause.txt.tmp; \
	sign_output=sign-output.tmp; \
	rm -f "$$output" "$$sign_output"; \
	trap 'rm -f "$$output" "$$sign_output"' EXIT; \
	start_nonce_hex=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(L1_RPC_URL)); \
	start_nonce=$$($(MISE_EXEC) cast to-dec "$$start_nonce_hex"); \
	superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(L1_RPC_URL)); \
	domain_separator=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "domainSeparator()(bytes32)" --rpc-url $(L1_RPC_URL)); \
	call_data=$$($(MISE_EXEC) cast calldata "pause(address)" $(ZERO_ADDRESS)); \
	call_data_hash=$$($(MISE_EXEC) cast keccak "$$call_data"); \
	echo "Starting nonce: $$start_nonce"; \
	i=0; while [ "$$i" -lt 20 ]; do \
		nonce=$$(($$start_nonce + $$i)); \
		echo "Signing with nonce $$nonce"; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $$superchain_config 0 $$call_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -data "$$signing_data" >"$$sign_output"; \
		cat "$$sign_output"; \
		signer=$$(awk '/^Signer:/ { print $$2 }' "$$sign_output"); \
		sig=$$(awk '/^Signature:/ { print $$2 }' "$$sign_output"); \
		[ -n "$$signer" ] && [ -n "$$sig" ] || { echo "invalid eip712sign output" >&2; exit 1; }; \
		printf "%s," "$$signer:$$nonce:$$sig" >>"$$output"; \
		i=$$(($$i + 1)); \
	done; \
	printf '\n' >>"$$output"; \
	mv "$$output" signatures-pause.txt

.PHONY: execute-pause
execute-pause:
	@test -n "$(SIGNATURES)" || { echo "SIGNATURES is required"; exit 1; }
	export $(PAUSE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: check-status
check-status:
	@superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(L1_RPC_URL)); \
	echo "SuperchainConfig address: $$superchain_config"; \
	$(MISE_EXEC) cast call "$$superchain_config" "paused(address)(bool)" $(ZERO_ADDRESS) --rpc-url $(L1_RPC_URL)

.PHONY: check-nonce
check-nonce:
	@echo "Incident Safe: $(INCIDENT_MULTISIG)"
	@$(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(L1_RPC_URL)
EOF

	cat >"$task_dir/FACILITATOR.md" <<'EOF'
# Facilitator Guide

Guide for collecting pre-signed `SuperchainConfig.pause` transactions and executing an emergency pause.

Replace `TASK_NETWORK=<network>` in every command with the selected task network.

## 1. Collect pause signatures

Ask each incident multisig signer to follow `config/<network>/README.md`. Each signer sends a `signatures-pause.txt` file containing signatures for 20 consecutive Safe nonces.

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

Send \`signatures-pause.txt\` to the facilitator through the approved secure channel.
EOF

echo "Created $config_dir"
echo "Next: cd active/evm/tasks/$task_id"
