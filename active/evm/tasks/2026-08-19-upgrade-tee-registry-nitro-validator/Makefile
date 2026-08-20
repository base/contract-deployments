include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK must be set on the make command line; run make TASK_NETWORK=sepolia <target>)
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK cannot be empty; run make TASK_NETWORK=sepolia <target>)
endif
PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
DEPLOYER = $(shell $(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))

DEPLOY_NITRO_SCRIPT := tasks/2026-08-19-upgrade-tee-registry-nitro-validator/script/DeployNitroValidatorStack.s.sol:DeployNitroValidatorStack
DEPLOY_REGISTRY_SCRIPT := tasks/2026-08-19-upgrade-tee-registry-nitro-validator/script/DeployTEEProverRegistryImpl.s.sol:DeployTEEProverRegistryImpl
SET_REGISTRY_IMPL_SCRIPT := tasks/2026-08-19-upgrade-tee-registry-nitro-validator/script/SetTEEProverRegistryImpl.s.sol:SetTEEProverRegistryImpl
SCRIPT_NAME := $(SET_REGISTRY_IMPL_SCRIPT)

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NEW_TEE_PROVER_REGISTRY_IMPL = $(shell jq -er '.teeProverRegistryImpl' $(ADDRESSES_JSON) 2>/dev/null)
NEW_P384_VERIFIER = $(shell jq -er '.p384Verifier' $(ADDRESSES_JSON) 2>/dev/null)
NEW_CERT_MANAGER = $(shell jq -er '.certManager' $(ADDRESSES_JSON) 2>/dev/null)
NEW_NITRO_VALIDATOR = $(shell jq -er '.nitroValidator' $(ADDRESSES_JSON) 2>/dev/null)

COMMON_ENV = RECORD_STATE_DIFF=$(RECORD_STATE_DIFF) \
	PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	TEE_PROVER_REGISTRY_PROXY=$(TEE_PROVER_REGISTRY_PROXY) \
	TEE_VERIFIER=$(TEE_VERIFIER) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) \
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

UPGRADE_ENV = $(COMMON_ENV) \
	TARGET_TEE_PROVER_REGISTRY_IMPL=$(NEW_TEE_PROVER_REGISTRY_IMPL) \
	ASSUMED_CURRENT_TEE_PROVER_REGISTRY_IMPL=$(OLD_TEE_PROVER_REGISTRY_IMPL)

ROLLBACK_ENV = $(COMMON_ENV) \
	TARGET_TEE_PROVER_REGISTRY_IMPL=$(OLD_TEE_PROVER_REGISTRY_IMPL) \
	ASSUMED_CURRENT_TEE_PROVER_REGISTRY_IMPL=$(NEW_TEE_PROVER_REGISTRY_IMPL)

ROLLBACK_NONCE_OFFSET ?= 1

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63 \
		github.com/base/nitro-validator@0ea0d12366b4fa44f9e07e4755f2ad36561cb674

.PHONY: validate-deploy-config
validate-deploy-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(CERT_MANAGER_OWNER)" || (echo "CERT_MANAGER_OWNER required" && exit 1)
	@test -n "$(CERT_MANAGER_REVOKER)" || (echo "CERT_MANAGER_REVOKER required" && exit 1)
	@test -n "$(DISPUTE_GAME_FACTORY_PROXY)" || (echo "DISPUTE_GAME_FACTORY_PROXY required" && exit 1)

.PHONY: validate-upgrade-config
validate-upgrade-config: validate-deploy-config
	@test -f "$(ADDRESSES_JSON)" || (echo "run make deploy first" && exit 1)
	@jq -e '.p384Verifier and .certManager and .nitroValidator and .teeProverRegistryImpl' "$(ADDRESSES_JSON)" >/dev/null

.PHONY: validate-nitro-deployment
validate-nitro-deployment: validate-deploy-config
	@test -f "$(ADDRESSES_JSON)" || (echo "deploy Nitro validator first" && exit 1)
	@jq -e '.p384Verifier and .certManager and .nitroValidator' "$(ADDRESSES_JSON)" >/dev/null

.PHONY: deploy
deploy: deploy-nitro-validator deploy-tee-registry-impl

.PHONY: deploy-nitro-validator
deploy-nitro-validator: validate-deploy-config
	cd $(PROJECT_DIR) && CERT_MANAGER_OWNER=$(CERT_MANAGER_OWNER) CERT_MANAGER_REVOKER=$(CERT_MANAGER_REVOKER) ADDRESSES_JSON=$(ADDRESSES_JSON) \
		FOUNDRY_PROFILE=nitro-deploy $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_NITRO_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

.PHONY: deploy-tee-registry-impl
deploy-tee-registry-impl: validate-deploy-config
	@test -f "$(ADDRESSES_JSON)" || (echo "deploy Nitro validator first" && exit 1)
	cd $(PROJECT_DIR) && DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) ADDRESSES_JSON=$(ADDRESSES_JSON) \
		FOUNDRY_PROFILE=tee-registry-deploy $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_REGISTRY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

.PHONY: verify-nitro-validator
verify-nitro-validator: validate-nitro-deployment
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
verify-tee-registry-impl: validate-upgrade-config
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; \
		mkdir -p $(PROJECT_DIR)/lib/contracts/lib; \
		ln -sfn ../../nitro-validator $(PROJECT_DIR)/lib/contracts/lib/nitro-validator; \
		ln -sfn ../../openzeppelin-contracts-upgradeable $(PROJECT_DIR)/lib/contracts/lib/openzeppelin-contracts-upgradeable; \
		trap 'rm -f $(PROJECT_DIR)/lib/contracts/lib/nitro-validator $(PROJECT_DIR)/lib/contracts/lib/openzeppelin-contracts-upgradeable' EXIT; \
		cd $(PROJECT_DIR); \
		RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_OPTIMIZER_RUNS=999999 FOUNDRY_EVM_VERSION=cancun \
		$(MISE_EXEC) forge verify-contract $(NEW_TEE_PROVER_REGISTRY_IMPL) src/L1/proofs/tee/TEEProverRegistry.sol:TEEProverRegistry \
		--root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
		--constructor-args $(shell $(MISE_EXEC) cast abi-encode "constructor(address,address)" $(NEW_NITRO_VALIDATOR) $(DISPUTE_GAME_FACTORY_PROXY)) \
		--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations 999999 \
		--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: gen-validation-cb
gen-validation-cb: validate-upgrade-config deps-signer-tool
	$(call GEN_VALIDATION,$(SET_REGISTRY_IMPL_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: validate-upgrade-config deps-signer-tool
	$(call GEN_VALIDATION,$(SET_REGISTRY_IMPL_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-cb-rollback
gen-validation-cb-rollback: validate-upgrade-config deps-signer-tool
	$(call GEN_VALIDATION,$(SET_REGISTRY_IMPL_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer-rollback.json,$(ROLLBACK_ENV) SAFE_NONCE_$(call ADDR_UPPER,$(PROXY_ADMIN_OWNER))=$(shell expr $(call GET_NONCE,$(PROXY_ADMIN_OWNER)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(CB_MULTISIG))=$(shell expr $(call GET_NONCE,$(CB_MULTISIG)) + $(ROLLBACK_NONCE_OFFSET)))

.PHONY: gen-validation-sc-rollback
gen-validation-sc-rollback: validate-upgrade-config deps-signer-tool
	$(call GEN_VALIDATION,$(SET_REGISTRY_IMPL_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer-rollback.json,$(ROLLBACK_ENV) SAFE_NONCE_$(call ADDR_UPPER,$(PROXY_ADMIN_OWNER))=$(shell expr $(call GET_NONCE,$(PROXY_ADMIN_OWNER)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(BASE_SECURITY_COUNCIL))=$(shell expr $(call GET_NONCE,$(BASE_SECURITY_COUNCIL)) + $(ROLLBACK_NONCE_OFFSET)))

.PHONY: approve-cb
approve-cb: validate-upgrade-config
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc: validate-upgrade-config
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute: validate-upgrade-config
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,0x)

.PHONY: approve-cb-rollback
approve-cb-rollback: validate-upgrade-config
	export $(ROLLBACK_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc-rollback
approve-sc-rollback: validate-upgrade-config
	export $(ROLLBACK_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-rollback
execute-rollback: validate-upgrade-config
	export $(ROLLBACK_ENV); $(call MULTISIG_EXECUTE,0x)
