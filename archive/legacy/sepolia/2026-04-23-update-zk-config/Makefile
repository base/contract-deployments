include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
UPDATE_ZK_CONFIG_SCRIPT_NAME = script/UpdateZkConfig.s.sol:UpdateZkConfig
UPDATE_ZK_CONFIG_CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
UPDATE_ZK_CONFIG_SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

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
.PHONY: deploy-zk-verifier
deploy-zk-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployZkVerifier.s.sol:DeployZkVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

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
# Update ZK config (multisig)
##
.PHONY: gen-validation-update-zk-config-cb
gen-validation-update-zk-config-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_ZK_CONFIG_SCRIPT_NAME),$(CB_MULTISIG),$(UPDATE_ZK_CONFIG_CB_SENDER),update-zk-config-cb-signer.json,)

.PHONY: gen-validation-update-zk-config-sc
gen-validation-update-zk-config-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_ZK_CONFIG_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(UPDATE_ZK_CONFIG_SC_SENDER),update-zk-config-sc-signer.json,)

.PHONY: approve-update-zk-config-cb
approve-update-zk-config-cb: SCRIPT_NAME := $(UPDATE_ZK_CONFIG_SCRIPT_NAME)
approve-update-zk-config-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-zk-config-sc
approve-update-zk-config-sc: SCRIPT_NAME := $(UPDATE_ZK_CONFIG_SCRIPT_NAME)
approve-update-zk-config-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-zk-config
execute-update-zk-config: SCRIPT_NAME := $(UPDATE_ZK_CONFIG_SCRIPT_NAME)
execute-update-zk-config:
	$(call MULTISIG_EXECUTE,0x)
