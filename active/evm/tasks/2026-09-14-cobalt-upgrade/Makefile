include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

# Cobalt rolls out across several networks from this one task directory, so the
# network is never defaulted. Select it on every command line:
#   make TASK_NETWORK=zeronet deploy
ifndef TASK_NETWORK
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json

TASK_DIR := tasks/2026-09-14-cobalt-upgrade
DEPLOY_CORE_SCRIPT := $(TASK_DIR)/script/DeployCobaltCoreImpls.s.sol:DeployCobaltCoreImpls
DEPLOY_PROOFS_SCRIPT := $(TASK_DIR)/script/DeployCobaltProofImpls.s.sol:DeployCobaltProofImpls
UPGRADE_SCRIPT := $(TASK_DIR)/script/ExecuteCobaltUpgrade.s.sol:ExecuteCobaltUpgrade
SCRIPT_NAME := $(UPGRADE_SCRIPT)

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NEW_OPTIMISM_PORTAL_IMPL = $(shell jq -er '.optimismPortalImpl' $(ADDRESSES_JSON) 2>/dev/null)
NEW_SYSTEM_CONFIG_IMPL = $(shell jq -er '.systemConfigImpl' $(ADDRESSES_JSON) 2>/dev/null)
NEW_DISPUTE_GAME_FACTORY_IMPL = $(shell jq -er '.disputeGameFactoryImpl' $(ADDRESSES_JSON) 2>/dev/null)
NEW_AGGREGATE_VERIFIER = $(shell jq -er '.aggregateVerifier' $(ADDRESSES_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_PROXY = $(shell jq -er '.protocolVersionsProxy' $(ADDRESSES_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_IMPL = $(shell jq -er '.protocolVersionsImpl' $(ADDRESSES_JSON) 2>/dev/null)
OPTIMISM_PORTAL_IMPL_CTOR_ARGS = $(shell jq -er '.optimismPortalImplConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_PROXY_CTOR_ARGS = $(shell jq -er '.protocolVersionsProxyConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)
AGGREGATE_VERIFIER_CTOR_ARGS = $(shell jq -er '.aggregateVerifierConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)

DEPLOY_ENV = ADDRESSES_JSON=$(ADDRESSES_JSON) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	L2_GENESIS_BLOCK_NUMBER=$(L2_GENESIS_BLOCK_NUMBER) \
	L2_GENESIS_TIMESTAMP=$(L2_GENESIS_TIMESTAMP) \
	L2_BLOCK_TIME=$(L2_BLOCK_TIME) \
	AGGREGATE_VERIFIER_TEE_IMAGE_HASH=$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH) \
	AGGREGATE_VERIFIER_ZK_RANGE_HASH=$(AGGREGATE_VERIFIER_ZK_RANGE_HASH) \
	AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH)

UPGRADE_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	SYSTEM_CONFIG=$(SYSTEM_CONFIG) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	OLD_OPTIMISM_PORTAL_IMPL=$(OLD_OPTIMISM_PORTAL_IMPL) \
	OLD_SYSTEM_CONFIG_IMPL=$(OLD_SYSTEM_CONFIG_IMPL) \
	OLD_DISPUTE_GAME_FACTORY_IMPL=$(OLD_DISPUTE_GAME_FACTORY_IMPL) \
	OLD_AGGREGATE_VERIFIER=$(OLD_AGGREGATE_VERIFIER) \
	NEW_OPTIMISM_PORTAL_IMPL=$(NEW_OPTIMISM_PORTAL_IMPL) \
	NEW_SYSTEM_CONFIG_IMPL=$(NEW_SYSTEM_CONFIG_IMPL) \
	NEW_DISPUTE_GAME_FACTORY_IMPL=$(NEW_DISPUTE_GAME_FACTORY_IMPL) \
	NEW_AGGREGATE_VERIFIER=$(NEW_AGGREGATE_VERIFIER) \
	PROTOCOL_VERSIONS_PROXY=$(PROTOCOL_VERSIONS_PROXY) \
	PROTOCOL_VERSIONS_IMPL=$(PROTOCOL_VERSIONS_IMPL) \
	PROTOCOL_VERSIONS_INCIDENT_RESPONDER=$(PROTOCOL_VERSIONS_INCIDENT_RESPONDER) \
	PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION) \
	PROTOCOL_VERSIONS_INITIAL_SCHEDULE=$(PROTOCOL_VERSIONS_INITIAL_SCHEDULE)

##
# Dependencies
##
# Prerequisites merge with the root `deps` rule, so these run after `forge-deps`
# has installed base/contracts at BASE_CONTRACTS_COMMIT.
.PHONY: deps
deps: task-extra-deps apply-patches

# The shared project installs only forge-std, solady and lib-keccak. Building the
# Cobalt implementations from source additionally needs base/contracts' own pinned
# dependencies, matching the versions in its justfile.
.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63 \
		github.com/transmissions11/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc

# Zeronet runs a SystemConfig patched to raise MAX_GAS_LIMIT to 2e9. Cobalt changes
# SystemConfig, so the patch is re-applied on top of the pinned commit rather than
# silently reverting the live chain to the stock 5e8 limit.
.PHONY: apply-patches
apply-patches:
	cd $(PROJECT_DIR)/lib/contracts && patch -p1 --forward < $(CURDIR)/patch/max-gas-limit.patch

##
# Deployment
##
.PHONY: deploy
deploy: deploy-core deploy-proofs

# base/contracts pins OptimismPortal2, SystemConfig, DisputeGameFactory and Proxy to
# 5000 optimizer runs, and ProtocolVersions and AggregateVerifier to 999999. The two
# deploy steps exist to reproduce those settings exactly.
.PHONY: deploy-core
deploy-core:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(DEPLOY_ENV) FOUNDRY_PROFILE=cobalt-core-deploy \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_CORE_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

.PHONY: deploy-proofs
deploy-proofs:
	cd $(PROJECT_DIR) && $(DEPLOY_ENV) FOUNDRY_PROFILE=cobalt-proofs-deploy \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_PROOFS_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

##
# Source verification
##
VERIFY_COMMON = --root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
	--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 \
	--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
	--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: verify-core
verify-core:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=5000 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_OPTIMISM_PORTAL_IMPL) src/L1/OptimismPortal2.sol:OptimismPortal2 \
		--constructor-args $(OPTIMISM_PORTAL_IMPL_CTOR_ARGS) \
		--num-of-optimizations 5000 $(VERIFY_COMMON)
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=5000 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_SYSTEM_CONFIG_IMPL) src/L1/SystemConfig.sol:SystemConfig \
		--num-of-optimizations 5000 $(VERIFY_COMMON)
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=5000 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_DISPUTE_GAME_FACTORY_IMPL) src/L1/proofs/DisputeGameFactory.sol:DisputeGameFactory \
		--num-of-optimizations 5000 $(VERIFY_COMMON)
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=5000 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_PROXY) src/universal/Proxy.sol:Proxy \
		--constructor-args $(PROTOCOL_VERSIONS_PROXY_CTOR_ARGS) \
		--num-of-optimizations 5000 $(VERIFY_COMMON)

.PHONY: verify-proofs
verify-proofs:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=999999 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_IMPL) src/L1/ProtocolVersions.sol:ProtocolVersions \
		--num-of-optimizations 999999 $(VERIFY_COMMON)
	cd $(PROJECT_DIR) && RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=999999 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) src/L1/proofs/AggregateVerifier.sol:AggregateVerifier \
		--constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
		--num-of-optimizations 999999 $(VERIFY_COMMON)

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
