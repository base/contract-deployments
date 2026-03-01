include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

# Map config variables to script variables
L1_SYSTEM_CONFIG_ADDRESS ?= $(SYSTEM_CONFIG)
SYSTEM_CONFIG_OWNER ?= $(INCIDENT_MULTISIG)

ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

RPC_URL = $(L1_RPC_URL)
# SCRIPT_NAME can be a Solidity file path (not just a class name); forge accepts both.
SCRIPT_NAME = lib/base-contracts/script/deploy/l1/SetGasLimit.sol

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" -a "$(OP_COMMIT)" != "TODO" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(L1_SYSTEM_CONFIG_ADDRESS)" || (echo "L1_SYSTEM_CONFIG_ADDRESS required" && exit 1)
	@test -n "$(SYSTEM_CONFIG_OWNER)" || (echo "SYSTEM_CONFIG_OWNER required" && exit 1)
	@test -n "$(OLD_GAS_LIMIT)" -a "$(OLD_GAS_LIMIT)" != "TODO" || (echo "OLD_GAS_LIMIT required" && exit 1)
	@test -n "$(NEW_GAS_LIMIT)" -a "$(NEW_GAS_LIMIT)" != "TODO" || (echo "NEW_GAS_LIMIT required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: sign-upgrade
sign-upgrade: validate-config
	FROM_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	TO_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) lib/base-contracts/script/deploy/l1/SetGasLimit.sol \
	--sig "sign()"

.PHONY: execute-upgrade
execute-upgrade: validate-config
	FROM_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	TO_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: sign-rollback
sign-rollback: validate-config
	FROM_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	TO_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	SAFE_NONCE=$(shell expr $$(cast call $(SYSTEM_CONFIG_OWNER) "nonce()" --rpc-url $(L1_RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) lib/base-contracts/script/deploy/l1/SetGasLimit.sol \
	--sig "sign()"

.PHONY: execute-rollback
execute-rollback: validate-config
	FROM_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	TO_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	SAFE_NONCE=$(shell expr $$(cast call $(SYSTEM_CONFIG_OWNER) "nonce()" --rpc-url $(L1_RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
