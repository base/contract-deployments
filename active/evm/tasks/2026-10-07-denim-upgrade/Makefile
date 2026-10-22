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
UPGRADE_SCRIPT := $(TASK_DIR)/script/$(if $(UPGRADE_SCRIPT_NAME),$(UPGRADE_SCRIPT_NAME),ExecuteDenimUpgrade).s.sol:$(if $(UPGRADE_SCRIPT_NAME),$(UPGRADE_SCRIPT_NAME),ExecuteDenimUpgrade)
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

ifneq ($(filter ExecuteDenimUpgradeWithL2Predeploys ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME)),)
impl = $(shell jq -er '.$(1)' $(ADDRESSES_JSON) 2>/dev/null)
UPGRADE_ENV += OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	L2_RPC_URL=$(L2_RPC_URL) \
	L2_TO_L1_MESSAGE_PASSER_IMPL=$(call impl,l2ToL1MessagePasser) \
	L1_BLOCK_IMPL=$(call impl,l1Block) \
	SEQUENCER_FEE_VAULT_IMPL=$(call impl,sequencerFeeVault) \
	BASE_FEE_VAULT_IMPL=$(call impl,baseFeeVault) \
	L1_FEE_VAULT_IMPL=$(call impl,l1FeeVault) \
	FEE_VAULT_RECIPIENT=$(FEE_VAULT_RECIPIENT) \
	FEE_VAULT_MIN_WITHDRAWAL_AMOUNT=$(FEE_VAULT_MIN_WITHDRAWAL_AMOUNT) \
	FEE_VAULT_WITHDRAWAL_NETWORK=$(FEE_VAULT_WITHDRAWAL_NETWORK)

.PHONY: check-implementations
check-implementations:
	@jq -e '[.aggregateVerifier, .l2ToL1MessagePasser, .l1Block, .sequencerFeeVault, .baseFeeVault, .l1FeeVault $(MAINNET_IMPLEMENTATIONS)] | all(.[]; type == "string" and test("^0x[0-9a-fA-F]{40}$$") and ascii_downcase != "0x0000000000000000000000000000000000000000")' "$(ADDRESSES_JSON)" >/dev/null 2>&1 || \
		{ echo 'Deploy AggregateVerifier and $(if $(filter ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME)),all thirteen L2 implementations and LegacyMigrator,all five L2 implementations) into $(ADDRESSES_JSON) before validation, approval or execution'; exit 1; }

approve-cb approve-sc execute: check-implementations
endif

##
# Deployment
##
# base/contracts builds AggregateVerifier with 999999 optimizer runs and no bytecode hash.
AGGREGATE_VERIFIER_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy
deploy:
ifneq ($(filter ExecuteDenimUpgradeWithL2Predeploys ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME)),)
	@test ! -f "$(ADDRESSES_JSON)" || jq -e '[.l2ToL1MessagePasser, .l1Block, .sequencerFeeVault, .baseFeeVault, .l1FeeVault $(MAINNET_IMPLEMENTATIONS)] | all(.[]; . == null)' "$(ADDRESSES_JSON)" >/dev/null || \
		{ echo 'deploy replaces addresses.json; deploy AggregateVerifier before deploy-l2'; exit 1; }
endif
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(VERIFIER_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

DEPLOY_PREDEPLOYS_SCRIPT := $(TASK_DIR)/script/DeployL2PredeployImpls.s.sol:DeployL2PredeployImpls
DEPLOY_FEE_VAULTS_SCRIPT := $(TASK_DIR)/script/DeployFeeVaultImpls.s.sol:DeployFeeVaultImpls

.PHONY: deploy-l2
deploy-l2:
	@test -n "$(filter ExecuteDenimUpgradeWithL2Predeploys ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME))" || \
		{ echo 'deploy-l2 requires the combined upgrade script in config/$(TASK_NETWORK)/.env'; exit 1; }
	@jq -e '.aggregateVerifier | type == "string" and test("^0x[0-9a-fA-F]{40}$$") and ascii_downcase != "0x0000000000000000000000000000000000000000"' "$(ADDRESSES_JSON)" >/dev/null 2>&1 || \
		{ echo 'Run deploy before deploy-l2; it initializes $(ADDRESSES_JSON)'; exit 1; }
	cd $(PROJECT_DIR) && ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(DEPLOY_PREDEPLOYS_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
	cd $(PROJECT_DIR) && ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(DEPLOY_FEE_VAULTS_SCRIPT) \
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
gen-validation-cb: $(if $(filter ExecuteDenimUpgradeWithL2Predeploys ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME)),check-implementations) deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: $(if $(filter ExecuteDenimUpgradeWithL2Predeploys ExecuteDenimUpgradeWithAllL2Predeploys,$(UPGRADE_SCRIPT_NAME)),check-implementations) deps-signer-tool
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

ifeq ($(UPGRADE_SCRIPT_NAME),ExecuteDenimUpgradeWithAllL2Predeploys)
TASK_PROJECT_DIR := $(CURDIR)
MAINNET_IMPLEMENTATIONS = , .optimismMintableERC721Factory, .operatorFeeVault, .schemaRegistry, .eas, .l2CrossDomainMessenger, .l2StandardBridge, .optimismMintableERC20Factory, .l2ERC721Bridge, .legacyMigrator
MAINNET_CONFIG_ENV = FACTORY_BRIDGE=$(FACTORY_BRIDGE) REMOTE_CHAIN_ID=$(REMOTE_CHAIN_ID) \
	L1_CROSS_DOMAIN_MESSENGER=$(L1_CROSS_DOMAIN_MESSENGER) L1_STANDARD_BRIDGE=$(L1_STANDARD_BRIDGE) \
	L1_ERC721_BRIDGE=$(L1_ERC721_BRIDGE) ERC20_FACTORY_BRIDGE=$(ERC20_FACTORY_BRIDGE) \
	OPERATOR_FEE_VAULT_RECIPIENT=$(OPERATOR_FEE_VAULT_RECIPIENT) \
	OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT=$(OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT) \
	OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK=$(OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK)
UPGRADE_ENV += $(MAINNET_CONFIG_ENV) \
	ERC721_FACTORY_IMPL=$(call impl,optimismMintableERC721Factory) \
	OPERATOR_FEE_VAULT_IMPL=$(call impl,operatorFeeVault) \
	SCHEMA_REGISTRY_IMPL=$(call impl,schemaRegistry) EAS_IMPL=$(call impl,eas) \
	MESSENGER_IMPL=$(call impl,l2CrossDomainMessenger) BRIDGE_IMPL=$(call impl,l2StandardBridge) \
	ERC20_FACTORY_IMPL=$(call impl,optimismMintableERC20Factory) ERC721_BRIDGE_IMPL=$(call impl,l2ERC721Bridge) \
	LEGACY_MIGRATOR=$(call impl,legacyMigrator)

clean-lib: bootstrap-mise install-eip712sign
forge-deps: clean-lib
deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63

.PHONY: check-prover-hashes deploy-remaining-l2 build-multisig simulate test
check-prover-hashes:
	@for hash in "$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH)" "$(AGGREGATE_VERIFIER_ZK_RANGE_HASH)" "$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH)"; do \
		printf '%s\n' "$$hash" | grep -Eq '^0x[0-9a-fA-F]{64}$$' && \
		test "$$hash" != 0x0000000000000000000000000000000000000000000000000000000000000000 || \
		{ echo 'Confirm the reproducible mainnet v1.5.1-based prover hashes first'; exit 1; }; \
	done

deploy gen-validation-cb gen-validation-sc approve-cb approve-sc execute: check-prover-hashes
deps-signer-tool: check-prover-hashes

deploy-remaining-l2:
	@jq -e '[.aggregateVerifier, .l2ToL1MessagePasser, .l1Block, .sequencerFeeVault, .baseFeeVault, .l1FeeVault] | all(.[]; type == "string" and test("^0x[0-9a-fA-F]{40}$$") and ascii_downcase != "0x0000000000000000000000000000000000000000")' "$(ADDRESSES_JSON)" >/dev/null || \
		{ echo 'Run deploy and deploy-l2 first'; exit 1; }
	cd $(TASK_PROJECT_DIR) && $(AGGREGATE_VERIFIER_BUILD) $(MISE_EXEC) forge build
	@set -e; for script in DeployFactory DeployBridges DeployOperatorFeeVault DeployAttestations; do \
		cd $(TASK_PROJECT_DIR); $(MAINNET_CONFIG_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(AGGREGATE_VERIFIER_BUILD) \
		$(MISE_EXEC) forge script script/$$script.s.sol:$$script --rpc-url $(L2_RPC_URL) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv; \
	done

build-multisig:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge build $(TASK_DIR)/script/ExecuteDenimUpgradeWithAllL2Predeploys.s.sol

.PHONY: simulate-current
simulate-current: check-implementations check-prover-hashes
	cd $(PROJECT_DIR) && $(UPGRADE_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(UPGRADE_SCRIPT) \
		--sig "simulate(bytes)" 0x -vvvv

simulate test: build-multisig
	cd $(TASK_PROJECT_DIR) && $(UPGRADE_ENV) L1_RPC_URL=$(L1_RPC_URL) CB_MULTISIG=$(CB_MULTISIG) \
		$(MISE_EXEC) forge test -vv
endif
