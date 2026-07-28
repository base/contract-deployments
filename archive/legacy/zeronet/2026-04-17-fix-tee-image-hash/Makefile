include ../../Makefile
include ../../Multisig.mk
-include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
FIX_SCRIPT_NAME = script/FixTeeImageHash.s.sol:FixTeeImageHash
FIX_CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
FIX_SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
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
# Fix TEE image hash (multisig)
##
.PHONY: gen-validation-fix-cb
gen-validation-fix-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(FIX_SCRIPT_NAME),$(CB_MULTISIG),$(FIX_CB_SENDER),fix-tee-image-hash-cb-signer.json,)

.PHONY: gen-validation-fix-sc
gen-validation-fix-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(FIX_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(FIX_SC_SENDER),fix-tee-image-hash-sc-signer.json,)

.PHONY: approve-fix-cb
approve-fix-cb: SCRIPT_NAME := $(FIX_SCRIPT_NAME)
approve-fix-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-fix-sc
approve-fix-sc: SCRIPT_NAME := $(FIX_SCRIPT_NAME)
approve-fix-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-fix
execute-fix: SCRIPT_NAME := $(FIX_SCRIPT_NAME)
execute-fix:
	$(call MULTISIG_EXECUTE,0x)
