include ../../Makefile
include ../../Multisig.mk

TASK_NETWORK ?= mainnet
TASK_ID ?= 2026-06-18-beryl-1
TASK_DIR = tasks/$(TASK_ID)

include $(TASK_DIR)/config/$(TASK_NETWORK)/network.env
include $(TASK_DIR)/config/$(TASK_NETWORK)/.env

export BASE_CONTRACTS_COMMIT
export GAME_TYPE
export TEE_IMAGE_HASH
export ZK_RANGE_HASH
export ZK_AGGREGATE_HASH

SIGNER_TOOL_PATH = ../../signer-tool
VALIDATIONS_DIR = $(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)/validations
TASK_ORIGIN_DIR = $(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR = $(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)/signatures
RPC_URL = $(L1_RPC_URL)

SCRIPT_NAME = script/common/verifier-update/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
ADDRESSES_JSON = $(TASK_DIR)/addresses.json
UPDATE_VERIFIER_HASHES_ENV = ADDRESSES_JSON=$(ADDRESSES_JSON) PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) DISPUTE_GAME_FACTORY_PROXY=$(DISPUTE_GAME_FACTORY_PROXY) GAME_TYPE=$(GAME_TYPE) TEE_IMAGE_HASH=$(TEE_IMAGE_HASH) ZK_RANGE_HASH=$(ZK_RANGE_HASH) ZK_AGGREGATE_HASH=$(ZK_AGGREGATE_HASH)

##
# Deployment (EOA)
##
.PHONY: deploy-aggregate-verifier
deploy-aggregate-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	ADDRESSES_JSON=$(ADDRESSES_JSON) $(MISE_EXEC) forge script --rpc-url $(RPC_URL) script/common/verifier-update/DeployAggregateVerifier.s.sol:DeployAggregateVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv

##
# Update verifier hashes (multisig)
##
.PHONY: gen-validation-update-verifier-hashes-cb
gen-validation-update-verifier-hashes-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),coinbase-signer.json,$(UPDATE_VERIFIER_HASHES_ENV))

.PHONY: gen-validation-update-verifier-hashes-sc
gen-validation-update-verifier-hashes-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPDATE_VERIFIER_HASHES_ENV))

.PHONY: approve-update-verifier-hashes-cb
approve-update-verifier-hashes-cb: SCRIPT_NAME := $(SCRIPT_NAME)
approve-update-verifier-hashes-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-verifier-hashes-sc
approve-update-verifier-hashes-sc: SCRIPT_NAME := $(SCRIPT_NAME)
approve-update-verifier-hashes-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-verifier-hashes
execute-update-verifier-hashes: SCRIPT_NAME := $(SCRIPT_NAME)
execute-update-verifier-hashes:
	$(call MULTISIG_EXECUTE,0x)
