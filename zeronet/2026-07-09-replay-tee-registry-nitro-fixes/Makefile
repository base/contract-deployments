include ../../Makefile
include ../../Multisig.mk
-include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = 0x8C1a617BdB47342F9C17Ac8750E0b070c372C721
SCRIPT_NAME = script/ReplayTeeRegistryNitroFixes.s.sol:ReplayTeeRegistryNitroFixes
CB_SENDER := $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER := $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps clone-oz-upgradeable

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	forge install --no-git github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts-v5 && \
		cd lib/openzeppelin-contracts-v5 && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3
	git clone --no-checkout https://github.com/Vectorized/solady.git lib/solady-v0.0.245 && \
		cd lib/solady-v0.0.245 && git checkout e0ef35adb0ccd1032794731a995cb599bba7b537

.PHONY: clone-oz-upgradeable
clone-oz-upgradeable:
	rm -rf lib/openzeppelin-contracts-upgradeable
	git clone --no-recurse-submodules --depth 1 --branch $(OZ_UPGRADEABLE_TAG) \
		https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git \
		lib/openzeppelin-contracts-upgradeable
	rm -rf lib/openzeppelin-contracts-upgradeable/.git

##
# Deployment (EOA)
##
.PHONY: deploy-nitro
deploy-nitro:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployAndSetupNitroFinal.s.sol:DeployAndSetupNitroFinal \
		--account testnet-admin --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy-implementations
deploy-implementations:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployReplayImplementations.s.sol:DeployReplayImplementations \
		--account testnet-admin --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy
deploy: deploy-nitro
	$(MAKE) deploy-implementations

##
# Replay TEE registry and Nitro fixes (multisig)
##
.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,)

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,)

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
