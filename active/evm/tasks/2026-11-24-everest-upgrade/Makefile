include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required on the command line, e.g. make TASK_NETWORK=<network> $(MAKECMDGOALS))
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK must not be empty)
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)
TASK_DIR := tasks/2026-11-24-everest-upgrade
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json

# The replacement verifier is deployed with the pre-reviewed standby script, which copies every
# non-hash constructor input from CURRENT_AGGREGATE_VERIFIER.
DEPLOY_SCRIPT := ../../standby/evm/tasks/update-verifier-hashes/script/DeployAggregateVerifier.s.sol:DeployAggregateVerifier
SCRIPT_NAME := $(TASK_DIR)/script/ExecuteEverestUpgrade.s.sol:ExecuteEverestUpgrade

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NEW_AGGREGATE_VERIFIER = $(shell jq -er '.aggregateVerifier' $(ADDRESSES_JSON) 2>/dev/null)
AGGREGATE_VERIFIER_CTOR_ARGS = $(shell jq -er '.aggregateVerifierConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)

HASH_VARS := AGGREGATE_VERIFIER_TEE_IMAGE_HASH AGGREGATE_VERIFIER_ZK_RANGE_HASH AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH
UPGRADE_VARS := $(HASH_VARS) NEW_AGGREGATE_VERIFIER EVEREST_ACTIVATION_TIMESTAMP \
	PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION

VERIFIER_ENV = BASE_CONTRACTS_COMMIT=$(BASE_CONTRACTS_COMMIT) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	GAME_TYPE=$(GAME_TYPE) \
	CURRENT_AGGREGATE_VERIFIER=$(CURRENT_AGGREGATE_VERIFIER) \
	AGGREGATE_VERIFIER_TEE_IMAGE_HASH=$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH) \
	AGGREGATE_VERIFIER_ZK_RANGE_HASH=$(AGGREGATE_VERIFIER_ZK_RANGE_HASH) \
	AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH)

UPGRADE_ENV = $(VERIFIER_ENV) \
	PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	NEW_AGGREGATE_VERIFIER=$(NEW_AGGREGATE_VERIFIER) \
	EVEREST_ACTIVATION_TIMESTAMP=$(EVEREST_ACTIVATION_TIMESTAMP) \
	PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION) \
	PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION)

.PHONY: check-hashes check-upgrade-inputs
check-hashes:
	$(call require_vars,check-hashes,$(HASH_VARS))

check-upgrade-inputs:
	$(call require_vars,check-upgrade-inputs,$(UPGRADE_VARS))

##
# Deployment
##
# base/contracts builds AggregateVerifier with 999999 optimizer runs and no bytecode hash.
AGGREGATE_VERIFIER_BUILD = FOUNDRY_SOLC_VERSION=0.8.15 FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun FOUNDRY_VIA_IR=false

.PHONY: deploy
deploy: check-hashes bootstrap-mise
	@test ! -e "$(ADDRESSES_JSON)" || { echo "$(ADDRESSES_JSON) already exists; review the existing deployment before retrying"; exit 1; }
	cd $(PROJECT_DIR) && $(VERIFIER_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

# Verification runs with lib/contracts as the project root. Its sources import solady through a literal
# `lib/solady/...` path, so link it in for the duration of the command.
CONTRACTS_LIB := $(PROJECT_DIR)/lib/contracts/lib

.PHONY: verify
verify: bootstrap-mise
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -eu; mkdir -p $(CONTRACTS_LIB); \
		test ! -e $(CONTRACTS_LIB)/solady && test ! -L $(CONTRACTS_LIB)/solady; \
		ln -s ../../solady $(CONTRACTS_LIB)/solady; \
		trap 'rm -f $(CONTRACTS_LIB)/solady; rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
		cd $(PROJECT_DIR); RUST_LOG=off $(AGGREGATE_VERIFIER_BUILD) $(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) \
			src/L1/proofs/AggregateVerifier.sol:AggregateVerifier --constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
			--root $(PROJECT_DIR)/lib/contracts --compilation-profile default --chain $(L1_CHAIN_ID) \
			--compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations 999999 \
			--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
			--verifier-api-key $(VERIFIER_API_KEY) --watch

##
# Validation files
##
.PHONY: gen-validation-cb gen-validation-sc
gen-validation-cb: check-upgrade-inputs deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))
ifneq ($(TASK_NETWORK),mainnet)
	@python3 $(REPO_ROOT)/scripts/standby-task.py skip-origin "$(VALIDATIONS_DIR)/base-signer.json"
endif

gen-validation-sc: check-upgrade-inputs deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))
ifneq ($(TASK_NETWORK),mainnet)
	@python3 $(REPO_ROOT)/scripts/standby-task.py skip-origin "$(VALIDATIONS_DIR)/security-council-signer.json"
endif

##
# Approve and execute
##
.PHONY: approve-cb approve-sc execute
approve-cb: check-upgrade-inputs bootstrap-mise
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

approve-sc: check-upgrade-inputs bootstrap-mise
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

execute: check-upgrade-inputs bootstrap-mise
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,0x)
