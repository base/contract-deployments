include ../../Makefile
include ../../Multisig.mk
-include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721

NITRO_SCRIPT_NAME = script/UpdateNitroVerifierId.s.sol:UpdateNitroVerifierId
REPLAY_SCRIPT_NAME = script/ReplayMayAggregate.s.sol:ReplayMayAggregate
NITRO_SENDER := $(shell cast call $(TEE_PROVER_REGISTRY_OWNER) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
CB_SENDER := $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER := $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps clone-oz-upgradeable apply-patches

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	forge install --no-git github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts-v5 && \
		cd lib/openzeppelin-contracts-v5 && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3 && rm -rf .git
	git clone --no-checkout https://github.com/Vectorized/solady.git lib/solady-v0.0.245 && \
		cd lib/solady-v0.0.245 && git checkout e0ef35adb0ccd1032794731a995cb599bba7b537 && rm -rf .git
	rm -rf lib/sp1-contracts/contracts/lib/openzeppelin-contracts
	mkdir -p lib/sp1-contracts/contracts/lib
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/sp1-contracts/contracts/lib/openzeppelin-contracts && \
		cd lib/sp1-contracts/contracts/lib/openzeppelin-contracts && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3 && rm -rf .git

.PHONY: clone-oz-upgradeable
clone-oz-upgradeable:
	rm -rf lib/openzeppelin-contracts-upgradeable
	git clone --no-recurse-submodules --depth 1 --branch $(OZ_UPGRADEABLE_TAG) \
		https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git \
		lib/openzeppelin-contracts-upgradeable
	rm -rf lib/openzeppelin-contracts-upgradeable/.git

.PHONY: apply-patches
apply-patches:
	cd lib/contracts && patch -p1 < ../../patch/max-gas-limit.patch

##
# Deployment (EOA)
##
.PHONY: deploy-system-config
deploy-system-config:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeploySystemConfig.s.sol:DeploySystemConfigScript \
		--account testnet-admin --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy-sp1-gateway
deploy-sp1-gateway:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeploySp1Gateway.s.sol:DeploySp1Gateway \
		--account testnet-admin --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy-zk-verifier
deploy-zk-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployZkVerifier.s.sol:DeployZkVerifier \
		--account testnet-admin --broadcast --verify \
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
		--account testnet-admin --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy
deploy: deploy-system-config deploy-sp1-gateway deploy-zk-verifier deploy-aggregate-verifier

##
# Validation
##
.PHONY: gen-validation-nitro
gen-validation-nitro: deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(NITRO_SCRIPT_NAME),,$(NITRO_SENDER),nitro-base-signer.json,)

.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(REPLAY_SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,)

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(REPLAY_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,)

##
# Execute Nitro verifier ID update (TEE_PROVER_REGISTRY_OWNER)
##
.PHONY: execute-nitro
execute-nitro: SCRIPT_NAME := $(NITRO_SCRIPT_NAME)
execute-nitro:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

##
# Replay May aggregate batch (PROXY_ADMIN_OWNER)
##
.PHONY: approve-cb
approve-cb: SCRIPT_NAME := $(REPLAY_SCRIPT_NAME)
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc: SCRIPT_NAME := $(REPLAY_SCRIPT_NAME)
approve-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute: SCRIPT_NAME := $(REPLAY_SCRIPT_NAME)
execute:
	$(call MULTISIG_EXECUTE,0x)
