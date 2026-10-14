include $(shell git rev-parse --show-toplevel)/scripts/Standby.mk

SCRIPT_DIR := ../../standby/evm/tasks/$(notdir $(CURDIR))/script
ifeq ($(PROJECT_DIR),$(CURDIR))
SCRIPT_DIR := script
endif
DEPLOY_SCRIPT := $(SCRIPT_DIR)/DeployAggregateVerifier.s.sol:DeployAggregateVerifier
UPDATE_SCRIPT := $(SCRIPT_DIR)/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
SCRIPT_NAME := $(UPDATE_SCRIPT)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
PRESTATE_JSON := $(CURDIR)/config/$(TASK_NETWORK)/prestate.json

# Match AggregateVerifier's default compilation profile at the supported contracts pin.
export FOUNDRY_SOLC_VERSION := 0.8.15
export FOUNDRY_OPTIMIZER := true
export FOUNDRY_OPTIMIZER_RUNS := 999999
export FOUNDRY_BYTECODE_HASH := none
export FOUNDRY_EVM_VERSION := cancun
export FOUNDRY_VIA_IR := false
BUILD_ENV = FOUNDRY_SOLC_VERSION=$(FOUNDRY_SOLC_VERSION) FOUNDRY_OPTIMIZER=$(FOUNDRY_OPTIMIZER) \
	FOUNDRY_OPTIMIZER_RUNS=$(FOUNDRY_OPTIMIZER_RUNS) FOUNDRY_BYTECODE_HASH=$(FOUNDRY_BYTECODE_HASH) \
	FOUNDRY_EVM_VERSION=$(FOUNDRY_EVM_VERSION) FOUNDRY_VIA_IR=$(FOUNDRY_VIA_IR)
VERIFIER_ENV = $(BUILD_ENV) BASE_CONTRACTS_COMMIT=$(BASE_CONTRACTS_COMMIT) \
	DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) GAME_TYPE=$(GAME_TYPE) \
	CURRENT_AGGREGATE_VERIFIER=$(CURRENT_AGGREGATE_VERIFIER) \
	AGGREGATE_VERIFIER_TEE_IMAGE_HASH=$(AGGREGATE_VERIFIER_TEE_IMAGE_HASH) \
	AGGREGATE_VERIFIER_ZK_RANGE_HASH=$(AGGREGATE_VERIFIER_ZK_RANGE_HASH) \
	AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH=$(AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH)
NEW_AGGREGATE_VERIFIER = $(shell jq -er '.aggregateVerifier' $(ADDRESSES_JSON) 2>/dev/null)
AGGREGATE_VERIFIER_CTOR_ARGS = $(shell jq -er '.aggregateVerifierConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)
UPDATE_ENV = $(VERIFIER_ENV) PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	NEW_AGGREGATE_VERIFIER=$(NEW_AGGREGATE_VERIFIER)
CHECK_ENV = $(UPDATE_ENV) PRESTATE_JSON=$(PRESTATE_JSON)

# Forge 1.5.1 ignores FOUNDRY_FS_PERMISSIONS, so artifact access needs a temporary config.
define WITH_ARTIFACT_PERMISSIONS
set -eu; config=$$(mktemp "$(PROJECT_DIR)/.verifier-foundry-XXXXXX"); \
	trap 'rm -f "$$config"' EXIT; \
	sed 's|^fs_permissions = .*|fs_permissions = [{ access = "read-write", path = "./" }, { access = "read-write", path = "$(CURDIR)/config/$(TASK_NETWORK)/" }]|' \
		"$(PROJECT_DIR)/foundry.toml" > "$$config"; \
	cd $(PROJECT_DIR); FOUNDRY_CONFIG="$$config" $(1)
endef
CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: validate-config build deploy verify validate gen-validation-cb gen-validation-sc approve-cb approve-sc execute post-check
validate-config:
	@python3 $(REPO_ROOT)/scripts/standby-task.py check-verifier --repo "$(REPO_ROOT)" --task "$(CURDIR)" --network "$(TASK_NETWORK)"

deps: validate-config
clean-lib forge-deps: validate-config

build: validate-config bootstrap-mise
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge build $(SCRIPT_DIR)/DeployAggregateVerifier.s.sol $(SCRIPT_DIR)/UpdateVerifierHashes.s.sol

deploy: validate-config bootstrap-mise
	@test ! -e "$(ADDRESSES_JSON)" || { echo "addresses.json already exists; review the existing deployment before retrying"; exit 1; }
	$(call WITH_ARTIFACT_PERMISSIONS,$(VERIFIER_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) $(MISE_EXEC) forge script \
		--rpc-url $(RPC_URL) $(DEPLOY_SCRIPT) --ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv)

CONTRACTS_LIB := $(PROJECT_DIR)/lib/contracts/lib
verify: validate-config bootstrap-mise
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -eu; mkdir -p $(CONTRACTS_LIB); \
		test ! -e $(CONTRACTS_LIB)/solady && test ! -L $(CONTRACTS_LIB)/solady; \
		ln -s ../../solady $(CONTRACTS_LIB)/solady; \
		trap 'rm -f $(CONTRACTS_LIB)/solady; rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
		cd $(PROJECT_DIR); RUST_LOG=off $(BUILD_ENV) $(MISE_EXEC) forge verify-contract $(NEW_AGGREGATE_VERIFIER) \
			src/L1/proofs/AggregateVerifier.sol:AggregateVerifier --constructor-args $(AGGREGATE_VERIFIER_CTOR_ARGS) \
			--root $(PROJECT_DIR)/lib/contracts --compilation-profile default --chain $(L1_CHAIN_ID) \
			--compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations 999999 \
			--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
			--verifier-api-key $(VERIFIER_API_KEY) --watch

validate: validate-config bootstrap-mise
	$(call WITH_ARTIFACT_PERMISSIONS,$(CHECK_ENV) $(MISE_EXEC) forge script --rpc-url $(RPC_URL) $(UPDATE_SCRIPT) --sig "check()")

gen-validation-cb: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPDATE_ENV))
ifneq ($(TASK_NETWORK),mainnet)
	@python3 $(REPO_ROOT)/scripts/standby-task.py skip-origin "$(VALIDATIONS_DIR)/base-signer.json"
endif

gen-validation-sc: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPDATE_ENV))
ifneq ($(TASK_NETWORK),mainnet)
	@python3 $(REPO_ROOT)/scripts/standby-task.py skip-origin "$(VALIDATIONS_DIR)/security-council-signer.json"
endif

approve-cb: validate-config bootstrap-mise
	export $(UPDATE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

approve-sc: validate-config bootstrap-mise
	export $(UPDATE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

execute: validate-config bootstrap-mise
	export $(UPDATE_ENV); $(call MULTISIG_EXECUTE,0x)

post-check: validate-config bootstrap-mise
	$(call WITH_ARTIFACT_PERMISSIONS,$(CHECK_ENV) $(MISE_EXEC) forge script --rpc-url $(RPC_URL) \
		$(SCRIPT_DIR)/UpdateVerifierHashes.s.sol:VerifyVerifierHashes --sig "checkAfterExecution()")
