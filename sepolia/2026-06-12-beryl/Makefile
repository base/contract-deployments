include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)

SCRIPT_NAME = UpdateVerifierHashes

# Robust extraction check: Verify cast results aren't empty before trimming
CB_SENDER_RAW := $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) 2>/dev/null)
SC_SENDER_RAW := $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) 2>/dev/null)

ifeq ($(CB_SENDER_RAW),)
  CB_SENDER := 0x0000000000000000000000000000000000000000
else
  CB_SENDER := $(shell echo "$(CB_SENDER_RAW)" | tr -d '[]' | cut -d',' -f1)
endif

ifeq ($(SC_SENDER_RAW),)
  SC_SENDER := 0x0000000000000000000000000000000000000000
else
  SC_SENDER := $(shell echo "$(SC_SENDER_RAW)" | tr -d '[]' | cut -d',' -f1)
endif

UPDATE_VERIFIER_HASHES_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) GAME_TYPE=$(GAME_TYPE) TEE_IMAGE_HASH=$(TEE_IMAGE_HASH) ZK_RANGE_HASH=$(ZK_RANGE_HASH) ZK_AGGREGATE_HASH=$(ZK_AGGREGATE_HASH)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Display available commands and explanations
	@echo "Base Deployment Workflow Terminal Tool"
	@echo "======================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

##
# Deployment (EOA)
##
.PHONY: deploy-aggregate-verifier
deploy-aggregate-verifier: ## Deploy and verify the new AggregateVerifier contract instance
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	$(MISE_EXEC) forge script --rpc-url $(RPC_URL) script/DeployAggregateVerifier.s.sol:DeployAggregateVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv

##
# Update verifier hashes (multisig)
##
.PHONY: gen-validation-update-verifier-hashes-cb
gen-validation-update-verifier-hashes-cb: deps-signer-tool ## Generate validation JSON files for Coinbase multisig
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),coinbase-signer.json,$(UPDATE_VERIFIER_HASHES_ENV))

.PHONY: gen-validation-update-verifier-hashes-sc
gen-validation-update-verifier-hashes-sc: deps-signer-tool ## Generate validation JSON files for Security Council multisig
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPDATE_VERIFIER_HASHES_ENV))

.PHONY: approve-update-verifier-hashes-cb
approve-update-verifier-hashes-cb: SCRIPT_NAME := $(SCRIPT_NAME)
approve-update-verifier-hashes-cb: ## Apply collected signatures to approve Coinbase multisig batch
ifndef SIGNATURES
	$(error SIGNATURES environment variable is not defined. Cannot submit approval.)
endif
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-verifier-hashes-sc
approve-update-verifier-hashes-sc: SCRIPT_NAME := $(SCRIPT_NAME)
approve-update-verifier-hashes-sc: ## Apply collected signatures to approve Security Council multisig batch
ifndef SIGNATURES
	$(error SIGNATURES environment variable is not defined. Cannot submit approval.)
endif
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-verifier-hashes
execute-update-verifier-hashes: SCRIPT_NAME := $(SCRIPT_NAME)
execute-update-verifier-hashes: ## Execute the finalized multisig upgrade transaction batch live
	$(call MULTISIG_EXECUTE,0x)

