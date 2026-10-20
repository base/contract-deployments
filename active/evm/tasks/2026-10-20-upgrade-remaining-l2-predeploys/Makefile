include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=sepolia $(MAKECMDGOALS))
endif
ifneq ($(TASK_NETWORK),sepolia)
$(error This invocation supports only TASK_NETWORK=sepolia)
endif

PROJECT_DIR := $(CURDIR)
include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
SCRIPT_NAME := script/UpgradeL2Predeploys.s.sol:UpgradeL2Predeploys
CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) 'getOwners()(address[])' --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) 'getOwners()(address[])' --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
impl = $(shell jq -er '.$(1)' $(ADDRESSES_JSON) 2>/dev/null)
CONFIG_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) FACTORY_BRIDGE=$(FACTORY_BRIDGE) \
	REMOTE_CHAIN_ID=$(REMOTE_CHAIN_ID) L2_RPC_URL=$(L2_RPC_URL) \
	OPERATOR_FEE_VAULT_RECIPIENT=$(OPERATOR_FEE_VAULT_RECIPIENT) \
	OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT=$(OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT) \
	OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK=$(OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK)
UPGRADE_ENV = $(CONFIG_ENV) OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	ERC721_FACTORY_IMPL=$(call impl,optimismMintableERC721Factory) \
	OPERATOR_FEE_VAULT_IMPL=$(call impl,operatorFeeVault) \
	SCHEMA_REGISTRY_IMPL=$(call impl,schemaRegistry) EAS_IMPL=$(call impl,eas)
PREDEPLOY_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

# Keep all dependency installation in the shared library directory.
clean-lib forge-deps: PROJECT_DIR := $(abspath ../..)
clean-lib: bootstrap-mise install-eip712sign
forge-deps: clean-lib
deps:
	cd ../.. && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63

.PHONY: build simulate-l2 deploy check-implementations gen-validation-cb gen-validation-sc approve-cb approve-sc execute
build:
	$(PREDEPLOY_BUILD) $(MISE_EXEC) forge build

simulate-l2: build
	$(CONFIG_ENV) L1_RPC_URL=$(L1_RPC_URL) OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) CB_MULTISIG=$(CB_MULTISIG) \
		L1_CROSS_DOMAIN_MESSENGER=$(L1_CROSS_DOMAIN_MESSENGER) \
		L1_STANDARD_BRIDGE=$(L1_STANDARD_BRIDGE) L1_ERC721_BRIDGE=$(L1_ERC721_BRIDGE) \
		$(PREDEPLOY_BUILD) $(MISE_EXEC) forge test -vv

deploy: build
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	$(CONFIG_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(PREDEPLOY_BUILD) $(MISE_EXEC) forge script \
		script/DeployFactory.s.sol:DeployFactory --rpc-url $(L2_RPC_URL) --ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
	ADDRESSES_JSON=$(ADDRESSES_JSON) $(PREDEPLOY_BUILD) $(MISE_EXEC) forge script \
		script/DeployOperatorFeeVault.s.sol:DeployOperatorFeeVault --rpc-url $(L2_RPC_URL) --ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
	ADDRESSES_JSON=$(ADDRESSES_JSON) $(PREDEPLOY_BUILD) $(MISE_EXEC) forge script \
		script/DeployAttestations.s.sol:DeployAttestations --rpc-url $(L2_RPC_URL) --ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

check-implementations:
	@jq -e '[.optimismMintableERC721Factory, .operatorFeeVault, .schemaRegistry, .eas] | all(.[]; type == "string" and test("^0x[0-9a-fA-F]{40}$$") and ascii_downcase != "0x0000000000000000000000000000000000000000")' "$(ADDRESSES_JSON)" >/dev/null 2>&1 || \
		{ echo 'Deploy all four implementations before validation, approval or execution'; exit 1; }

gen-validation-cb gen-validation-sc: check-implementations
deps-signer-tool: check-implementations
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))
approve-cb approve-sc execute: check-implementations
approve-cb:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))
approve-sc:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))
execute:
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,0x)
