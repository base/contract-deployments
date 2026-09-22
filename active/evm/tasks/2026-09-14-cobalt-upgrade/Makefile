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

EXPECTED_SYSTEM_CONFIG_VERSION ?= 3.14.0+max-gas-limit-2000M
PROTOCOL_VERSIONS_PREDEPLOYED ?= false
DEPLOY_TEE_WITH_COBALT ?= false

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)

ifneq ($(strip $(PROTOCOL_VERSIONS_DEPLOYMENT_JSON)),)
PROTOCOL_VERSIONS_DEPLOYMENT_JSON := $(abspath $(PROTOCOL_VERSIONS_DEPLOYMENT_JSON))
EXISTING_PROTOCOL_VERSIONS_PROXY = $(shell jq -r '.protocolVersionsProxy // empty' $(PROTOCOL_VERSIONS_DEPLOYMENT_JSON) 2>/dev/null)
EXISTING_PROTOCOL_VERSIONS_IMPL = $(shell jq -r '.protocolVersionsImpl // empty' $(PROTOCOL_VERSIONS_DEPLOYMENT_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_DEPLOY_ENV = \
	EXISTING_PROTOCOL_VERSIONS_PROXY=$(EXISTING_PROTOCOL_VERSIONS_PROXY) \
	EXISTING_PROTOCOL_VERSIONS_IMPL=$(EXISTING_PROTOCOL_VERSIONS_IMPL)
PROTOCOL_VERSIONS_DEPLOY_PREREQUISITE = validate-protocol-versions-deployment
endif

TASK_DIR := tasks/2026-09-14-cobalt-upgrade
DEPLOY_CORE_SCRIPT := $(TASK_DIR)/script/DeployCobaltCoreImpls.s.sol:DeployCobaltCoreImpls
DEPLOY_PROOFS_SCRIPT := $(TASK_DIR)/script/DeployCobaltProofImpls.s.sol:DeployCobaltProofImpls
DEPLOY_NITRO_SCRIPT := $(TASK_DIR)/script/DeployNitroValidatorStack.s.sol:DeployNitroValidatorStack
DEPLOY_TEE_REGISTRY_SCRIPT := $(TASK_DIR)/script/DeployTEEProverRegistryImpl.s.sol:DeployTEEProverRegistryImpl
UPGRADE_SCRIPT := $(TASK_DIR)/script/ExecuteCobaltUpgrade.s.sol:ExecuteCobaltUpgrade
SCRIPT_NAME := $(UPGRADE_SCRIPT)
DEPLOYER = $(shell $(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))

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
# `// empty` matters here: a bare `jq -er .missing` prints the literal "null" on stdout, which
# would make the cutover gate below read as populated before anything is deployed.
NEW_TEE_PROVER_REGISTRY_IMPL = $(shell jq -r '.teeProverRegistryImpl // empty' $(ADDRESSES_JSON) 2>/dev/null)
NEW_P384_VERIFIER = $(shell jq -r '.p384Verifier // empty' $(ADDRESSES_JSON) 2>/dev/null)
NEW_CERT_MANAGER = $(shell jq -r '.certManager // empty' $(ADDRESSES_JSON) 2>/dev/null)
NEW_NITRO_VALIDATOR = $(shell jq -r '.nitroValidator // empty' $(ADDRESSES_JSON) 2>/dev/null)

DEPLOY_ENV = ADDRESSES_JSON=$(ADDRESSES_JSON) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
	L2_GENESIS_BLOCK_NUMBER=$(L2_GENESIS_BLOCK_NUMBER) \
	L2_GENESIS_TIMESTAMP=$(L2_GENESIS_TIMESTAMP) \
	L2_BLOCK_TIME=$(L2_BLOCK_TIME) \
	AGGREGATE_VERIFIER_TEE_IMAGE_HASH=$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH) \
	AGGREGATE_VERIFIER_ZK_RANGE_HASH=$(AGGREGATE_VERIFIER_ZK_RANGE_HASH) \
	AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH) \
	EXPECTED_SYSTEM_CONFIG_VERSION=$(EXPECTED_SYSTEM_CONFIG_VERSION) \
	$(PROTOCOL_VERSIONS_DEPLOY_ENV)

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
	PROTOCOL_VERSIONS_PREDEPLOYED=$(PROTOCOL_VERSIONS_PREDEPLOYED) \
	PROTOCOL_VERSIONS_INITIAL_SCHEDULE=$(PROTOCOL_VERSIONS_INITIAL_SCHEDULE) \
	EXPECTED_SYSTEM_CONFIG_VERSION=$(EXPECTED_SYSTEM_CONFIG_VERSION) \
	$(TEE_UPGRADE_ENV)

# Networks that still need the hinted Nitro cutover pass these so ExecuteCobaltUpgrade
# appends a ProxyAdmin.upgrade for the registry.
ifneq ($(NEW_TEE_PROVER_REGISTRY_IMPL),)
TEE_UPGRADE_ENV = \
	TEE_PROVER_REGISTRY_PROXY=$(TEE_PROVER_REGISTRY_PROXY) \
	TEE_VERIFIER=$(TEE_VERIFIER) \
	PROPOSER=$(PROPOSER) \
	CHALLENGER=$(CHALLENGER) \
	CERT_MANAGER_OWNER=$(CERT_MANAGER_OWNER) \
	CERT_MANAGER_REVOKER=$(CERT_MANAGER_REVOKER) \
	OLD_TEE_PROVER_REGISTRY_IMPL=$(OLD_TEE_PROVER_REGISTRY_IMPL) \
	NEW_TEE_PROVER_REGISTRY_IMPL=$(NEW_TEE_PROVER_REGISTRY_IMPL) \
	OLD_NITRO_VERIFIER=$(OLD_NITRO_VERIFIER) \
	NEW_P384_VERIFIER=$(NEW_P384_VERIFIER) \
	NEW_CERT_MANAGER=$(NEW_CERT_MANAGER) \
	NEW_NITRO_VALIDATOR=$(NEW_NITRO_VALIDATOR)
endif

##
# Dependencies
##
# Prerequisites merge with the root `deps` rule, so these run after `forge-deps`
# has installed base/contracts at BASE_CONTRACTS_COMMIT.
.PHONY: deps
deps: task-extra-deps

ifneq ($(APPLY_MAX_GAS_LIMIT_PATCH),false)
deps: apply-patches
endif

# The shared project installs only forge-std, solady and lib-keccak. Building the
# Cobalt implementations from source additionally needs base/contracts' own pinned
# dependencies, matching the versions in its justfile.
.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63 \
		github.com/transmissions11/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/base/nitro-validator@0ea0d12366b4fa44f9e07e4755f2ad36561cb674

# Zeronet runs a SystemConfig patched to raise MAX_GAS_LIMIT to 2e9. Cobalt changes
# SystemConfig, so the patch is re-applied on top of the pinned commit rather than
# silently reverting the live chain to the stock 5e8 limit.
.PHONY: apply-patches
apply-patches:
	cd $(PROJECT_DIR)/lib/contracts && patch -p1 --forward < $(CURDIR)/patch/max-gas-limit.patch

.PHONY: validate-protocol-versions-deployment
validate-protocol-versions-deployment:
	@jq -e '.protocolVersionsProxy and .protocolVersionsImpl' "$(PROTOCOL_VERSIONS_DEPLOYMENT_JSON)" >/dev/null || \
		(echo "complete the standalone ProtocolVersions deployment first" && exit 1)

##
# Deployment
##
.PHONY: deploy
deploy:
	$(MAKE) TASK_NETWORK=$(TASK_NETWORK) deploy-core
	$(MAKE) TASK_NETWORK=$(TASK_NETWORK) deploy-proofs
ifeq ($(DEPLOY_TEE_WITH_COBALT),true)
	$(MAKE) TASK_NETWORK=$(TASK_NETWORK) deploy-nitro-validator
	$(MAKE) TASK_NETWORK=$(TASK_NETWORK) deploy-tee-registry-impl
endif

# base/contracts pins OptimismPortal2, SystemConfig, DisputeGameFactory and Proxy to
# 5000 optimizer runs, and ProtocolVersions and AggregateVerifier to 999999, and builds
# with no bytecode hash. Reproducing those settings is what makes the deployed bytecode
# verifiable, hence the two steps and the compiler overrides, which are kept identical
# to the ones the verify targets below use. The evm version request is inert at solc
# 0.8.15, which caps out at london, but it is set on both sides so they cannot diverge.
COBALT_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy-core
deploy-core: $(PROTOCOL_VERSIONS_DEPLOY_PREREQUISITE)
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(DEPLOY_ENV) $(COBALT_BUILD) FOUNDRY_OPTIMIZER_RUNS=5000 \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_CORE_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

.PHONY: deploy-proofs
deploy-proofs: $(PROTOCOL_VERSIONS_DEPLOY_PREREQUISITE)
	cd $(PROJECT_DIR) && $(DEPLOY_ENV) $(COBALT_BUILD) FOUNDRY_OPTIMIZER_RUNS=999999 \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_PROOFS_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

.PHONY: deploy-nitro-validator
deploy-nitro-validator:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && CERT_MANAGER_OWNER=$(CERT_MANAGER_OWNER) CERT_MANAGER_REVOKER=$(CERT_MANAGER_REVOKER) \
		ADDRESSES_JSON=$(ADDRESSES_JSON) FOUNDRY_PROFILE=nitro-deploy \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_NITRO_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

.PHONY: deploy-tee-registry-impl
deploy-tee-registry-impl:
	cd $(PROJECT_DIR) && DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) ADDRESSES_JSON=$(ADDRESSES_JSON) \
		FOUNDRY_PROFILE=tee-registry-deploy \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_TEE_REGISTRY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

##
# Source verification
##
# Verification runs with lib/contracts as the project root, because that is the only
# root from which the target paths resolve. base/contracts then imports its own
# dependencies through literal `lib/<dep>/...` paths, which resolve against that root
# too, but the build keeps them a level up in active/evm/lib. Link them in for the
# duration of the command and remove them afterwards: left in place, every such import
# matches in two locations and the build fails as ambiguous.
VERIFY_DEPS = openzeppelin-contracts openzeppelin-contracts-upgradeable solady solmate
CONTRACTS_LIB = $(PROJECT_DIR)/lib/contracts/lib
LINK_VERIFY_DEPS = mkdir -p $(CONTRACTS_LIB); \
	trap 'rm -f $(foreach d,$(VERIFY_DEPS),$(CONTRACTS_LIB)/$(d)); rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
	for d in $(VERIFY_DEPS); do ln -sfn ../../$$d $(CONTRACTS_LIB)/$$d; done

VERIFY_ENV = RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

VERIFY_COMMON = --root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
	--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 \
	--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
	--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: verify-core
verify-core:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; $(LINK_VERIFY_DEPS); \
		cd $(PROJECT_DIR); \
		$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=5000 \
			$(MISE_EXEC) forge verify-contract $(NEW_OPTIMISM_PORTAL_IMPL) src/L1/OptimismPortal2.sol:OptimismPortal2 \
			--constructor-args $(OPTIMISM_PORTAL_IMPL_CTOR_ARGS) \
			--num-of-optimizations 5000 $(VERIFY_COMMON); \
		$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=5000 \
			$(MISE_EXEC) forge verify-contract $(NEW_SYSTEM_CONFIG_IMPL) src/L1/SystemConfig.sol:SystemConfig \
			--num-of-optimizations 5000 $(VERIFY_COMMON); \
		$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=5000 \
			$(MISE_EXEC) forge verify-contract $(NEW_DISPUTE_GAME_FACTORY_IMPL) src/L1/proofs/DisputeGameFactory.sol:DisputeGameFactory \
			--num-of-optimizations 5000 $(VERIFY_COMMON); \
		if [ "$(PROTOCOL_VERSIONS_PREDEPLOYED)" != "true" ]; then \
			$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=5000 \
				$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_PROXY) src/universal/Proxy.sol:Proxy \
				--constructor-args $(PROTOCOL_VERSIONS_PROXY_CTOR_ARGS) \
				--num-of-optimizations 5000 $(VERIFY_COMMON); \
		fi

.PHONY: verify-proofs
verify-proofs:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; $(LINK_VERIFY_DEPS); \
		cd $(PROJECT_DIR); \
		if [ "$(PROTOCOL_VERSIONS_PREDEPLOYED)" != "true" ]; then \
			$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=999999 \
				$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_IMPL) src/L1/ProtocolVersions.sol:ProtocolVersions \
				--num-of-optimizations 999999 $(VERIFY_COMMON); \
		fi; \
		$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=999999 \
			$(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) src/L1/proofs/AggregateVerifier.sol:AggregateVerifier \
			--constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
			--num-of-optimizations 999999 $(VERIFY_COMMON)

.PHONY: verify-nitro-validator
verify-nitro-validator:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	cd $(PROJECT_DIR)/lib/nitro-validator && FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_P384_VERIFIER) src/P384Verifier.sol:P384Verifier \
		--chain $(L1_CHAIN_ID) --compiler-version v0.8.26+commit.8a97fa7a --num-of-optimizations 10000 \
		--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) --watch
	cd $(PROJECT_DIR)/lib/nitro-validator && FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_CERT_MANAGER) src/CertManager.sol:CertManager \
		--constructor-args $(shell $(MISE_EXEC) cast abi-encode "constructor(address,address,address)" $(NEW_P384_VERIFIER) $(CERT_MANAGER_OWNER) $(CERT_MANAGER_REVOKER)) \
		--chain $(L1_CHAIN_ID) --compiler-version v0.8.26+commit.8a97fa7a --num-of-optimizations 10000 \
		--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) --watch
	cd $(PROJECT_DIR)/lib/nitro-validator && FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_NITRO_VALIDATOR) src/NitroValidator.sol:NitroValidator \
		--constructor-args $(shell $(MISE_EXEC) cast abi-encode "constructor(address,address)" $(NEW_CERT_MANAGER) $(NEW_P384_VERIFIER)) \
		--chain $(L1_CHAIN_ID) --compiler-version v0.8.26+commit.8a97fa7a --num-of-optimizations 10000 \
		--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: verify-tee-registry-impl
verify-tee-registry-impl:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; \
		mkdir -p $(CONTRACTS_LIB); \
		trap 'rm -f $(foreach d,$(VERIFY_DEPS) nitro-validator,$(CONTRACTS_LIB)/$(d)); rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
		for d in $(VERIFY_DEPS) nitro-validator; do ln -sfn ../../$$d $(CONTRACTS_LIB)/$$d; done; \
		cd $(PROJECT_DIR); \
		$(VERIFY_ENV) FOUNDRY_OPTIMIZER_RUNS=999999 \
		$(MISE_EXEC) forge verify-contract $(NEW_TEE_PROVER_REGISTRY_IMPL) src/L1/proofs/tee/TEEProverRegistry.sol:TEEProverRegistry \
		--constructor-args $(shell $(MISE_EXEC) cast abi-encode "constructor(address,address)" $(NEW_NITRO_VALIDATOR) $(DISPUTE_GAME_FACTORY_PROXY)) \
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
