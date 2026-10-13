include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

# Denim rolls out across several networks from this one task directory, so the network is never
# defaulted or read from the environment. Select it on every command line:
#   make TASK_NETWORK=zeronet deploy
ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)

TASK_DIR := tasks/2026-10-07-denim-upgrade
DEPLOY_SCRIPT := $(TASK_DIR)/script/DeployDenimProofImpls.s.sol:DeployDenimProofImpls
UPGRADE_SCRIPT := $(TASK_DIR)/script/ExecuteDenimUpgrade.s.sol:ExecuteDenimUpgrade
SCRIPT_NAME := $(UPGRADE_SCRIPT)

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NEW_AGGREGATE_VERIFIER = $(shell jq -er '.aggregateVerifier' $(ADDRESSES_JSON) 2>/dev/null)
AGGREGATE_VERIFIER_CTOR_ARGS = $(shell jq -er '.aggregateVerifierConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)

VERIFIER_ENV = DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	GAME_TYPE=$(GAME_TYPE) \
	OLD_AGGREGATE_VERIFIER=$(OLD_AGGREGATE_VERIFIER) \
	FAST_BLOCK_INTERVAL=$(FAST_BLOCK_INTERVAL) \
	FAST_INTERMEDIATE_BLOCK_INTERVAL=$(FAST_INTERMEDIATE_BLOCK_INTERVAL) \
	AGGREGATE_VERIFIER_TEE_IMAGE_HASH=$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH) \
	AGGREGATE_VERIFIER_ZK_RANGE_HASH=$(AGGREGATE_VERIFIER_ZK_RANGE_HASH) \
	AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH)

UPGRADE_ENV = $(VERIFIER_ENV) \
	PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	NEW_AGGREGATE_VERIFIER=$(NEW_AGGREGATE_VERIFIER) \
	PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP=$(PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP) \
	PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION) \
	PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION)

##
# Deployment
##
# base/contracts builds AggregateVerifier with 999999 optimizer runs and no bytecode hash.
AGGREGATE_VERIFIER_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy
deploy:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(VERIFIER_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

##
# Source verification
##
# Verification runs with lib/contracts as the project root. Its sources import their own
# dependencies through literal `lib/<dep>/...` paths, so link them in for the duration of the command.
VERIFY_DEPS = solady
CONTRACTS_LIB = $(PROJECT_DIR)/lib/contracts/lib
LINK_VERIFY_DEPS = mkdir -p $(CONTRACTS_LIB); \
	trap 'rm -f $(foreach d,$(VERIFY_DEPS),$(CONTRACTS_LIB)/$(d)); rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
	for d in $(VERIFY_DEPS); do ln -sfn ../../$$d $(CONTRACTS_LIB)/$$d; done

.PHONY: verify
verify:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; $(LINK_VERIFY_DEPS); \
		cd $(PROJECT_DIR); \
		RUST_LOG=off $(AGGREGATE_VERIFIER_BUILD) \
			$(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) \
			src/L1/proofs/AggregateVerifier.sol:AggregateVerifier \
			--constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
			--root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
			--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations 999999 \
			--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
			--verifier-api-key $(VERIFIER_API_KEY) --watch

##
# Validation files
##
.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))

##
# Approve and execute
##
.PHONY: approve-cb
approve-cb:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,0x)
