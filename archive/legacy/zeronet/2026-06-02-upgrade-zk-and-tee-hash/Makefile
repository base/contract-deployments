include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell $(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
UPDATE_VERIFIER_HASHES_SCRIPT_NAME = script/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
UPDATE_VERIFIER_HASHES_CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
UPDATE_VERIFIER_HASHES_SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

##
# Deployment (EOA)
##
.PHONY: deploy-aggregate-verifier
deploy-aggregate-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) script/DeployAggregateVerifier.s.sol:DeployAggregateVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

##
# Update verifier hashes (multisig)
##
.PHONY: gen-validation-update-verifier-hashes-cb
gen-validation-update-verifier-hashes-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_VERIFIER_HASHES_SCRIPT_NAME),$(CB_MULTISIG),$(UPDATE_VERIFIER_HASHES_CB_SENDER),base-signer.json,)

.PHONY: gen-validation-update-verifier-hashes-sc
gen-validation-update-verifier-hashes-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_VERIFIER_HASHES_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(UPDATE_VERIFIER_HASHES_SC_SENDER),base-signer-2.json,)

.PHONY: approve-update-verifier-hashes-cb
approve-update-verifier-hashes-cb: SCRIPT_NAME := $(UPDATE_VERIFIER_HASHES_SCRIPT_NAME)
approve-update-verifier-hashes-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-verifier-hashes-sc
approve-update-verifier-hashes-sc: SCRIPT_NAME := $(UPDATE_VERIFIER_HASHES_SCRIPT_NAME)
approve-update-verifier-hashes-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-verifier-hashes
execute-update-verifier-hashes: SCRIPT_NAME := $(UPDATE_VERIFIER_HASHES_SCRIPT_NAME)
execute-update-verifier-hashes:
	$(call MULTISIG_EXECUTE,0x)
