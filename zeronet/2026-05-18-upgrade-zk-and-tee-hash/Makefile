include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
UPDATE_VERIFIER_HASHES_SCRIPT_NAME = script/UpdateVerifierHashes.s.sol:UpdateVerifierHashes
UPDATE_VERIFIER_HASHES_CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
UPDATE_VERIFIER_HASHES_SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts-v5 && \
		cd lib/openzeppelin-contracts-v5 && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3
	git clone --no-checkout https://github.com/Vectorized/solady.git lib/solady-v0.0.245 && \
		cd lib/solady-v0.0.245 && git checkout e0ef35adb0ccd1032794731a995cb599bba7b537

##
# Deployment (EOA)
##
.PHONY: deploy-aggregate-verifier
deploy-aggregate-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployAggregateVerifier.s.sol:DeployAggregateVerifier \
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
