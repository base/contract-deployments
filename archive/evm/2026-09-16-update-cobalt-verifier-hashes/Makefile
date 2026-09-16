include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifndef TASK_NETWORK
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)

TASK_DIR := tasks/2026-09-16-update-cobalt-verifier-hashes
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
FORGE_ADDRESSES_JSON := $(TASK_DIR)/config/$(TASK_NETWORK)/addresses.json
DEPLOY_SCRIPT := script/common/verifier-update/DeployAggregateVerifier.s.sol:DeployAggregateVerifier
UPDATE_SCRIPT := script/common/verifier-update/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
SCRIPT_NAME := $(UPDATE_SCRIPT)

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NEW_AGGREGATE_VERIFIER = $(shell jq -er '.aggregateVerifier' $(ADDRESSES_JSON) 2>/dev/null)
AGGREGATE_VERIFIER_CTOR_ARGS = $(shell jq -er '.aggregateVerifierConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)

HASH_ENV = DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	GAME_TYPE=$(GAME_TYPE) \
	TEE_IMAGE_HASH=$(TEE_IMAGE_HASH) \
	ZK_RANGE_HASH=$(ZK_RANGE_HASH) \
	ZK_AGGREGATE_HASH=$(ZK_AGGREGATE_HASH) \
	ADDRESSES_JSON=$(FORGE_ADDRESSES_JSON)

UPDATE_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) $(HASH_ENV)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63 \
		github.com/transmissions11/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc

COBALT_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy
deploy:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(HASH_ENV) $(COBALT_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

VERIFY_DEPS = openzeppelin-contracts openzeppelin-contracts-upgradeable solady solmate
CONTRACTS_LIB = $(PROJECT_DIR)/lib/contracts/lib
LINK_VERIFY_DEPS = mkdir -p $(CONTRACTS_LIB); \
	trap 'rm -f $(foreach d,$(VERIFY_DEPS),$(CONTRACTS_LIB)/$(d)); rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
	for d in $(VERIFY_DEPS); do ln -sfn ../../$$d $(CONTRACTS_LIB)/$$d; done

VERIFY_COMMON = --root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
	--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 \
	--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
	--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: verify
verify:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; $(LINK_VERIFY_DEPS); \
		cd $(PROJECT_DIR); \
		RUST_LOG=off $(COBALT_BUILD) \
			$(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) \
			src/L1/proofs/AggregateVerifier.sol:AggregateVerifier \
			--constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
			--num-of-optimizations 999999 $(VERIFY_COMMON)

.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPDATE_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPDATE_ENV))

.PHONY: approve-cb
approve-cb:
	export $(UPDATE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	export $(UPDATE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	export $(UPDATE_ENV); $(call MULTISIG_EXECUTE,0x)
