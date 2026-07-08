include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER := $(shell cast wallet address --account testnet-admin)
ACTIVATE_MULTIPROOF_SCRIPT_NAME = script/ActivateMultiproofStack.s.sol:ActivateMultiproofStack
MULTIPROOF_CB_SENDER := $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
MULTIPROOF_SC_SENDER := $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: apply-patches
apply-patches:
	cd lib/contracts && patch -p1 < ../../patch/asr-reset-anchor-game.patch

.PHONY: deps
deps: task-extra-deps clone-oz-upgradeable apply-patches

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	forge install --no-git github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3
	forge install --no-git github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc
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
# Deployment
##
.PHONY: deploy-nitro-verifier
deploy-nitro-verifier:
	forge script --rpc-url $(L1_RPC_URL) script/DeployNitroVerifier.s.sol:DeployNitroVerifier \
		--account testnet-admin --broadcast -vvvv --sender $(DEPLOYER)

.PHONY: deploy-multiproof
deploy-multiproof:
	forge script --rpc-url $(L1_RPC_URL) script/DeployMultiproofStack.s.sol:DeployMultiproofStack \
		--account testnet-admin --broadcast -vvvv --sender $(DEPLOYER)

.PHONY: setup-nitro
setup-nitro:
	forge script --rpc-url $(L1_RPC_URL) script/SetupNitroEnclaveVerifier.s.sol:SetupNitroEnclaveVerifier \
		--account testnet-admin --broadcast -vvvv --sender $(DEPLOYER)

##
# Activate Multiproof
##

.PHONY: gen-validation-multiproof-cb
gen-validation-multiproof-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(ACTIVATE_MULTIPROOF_SCRIPT_NAME),$(CB_MULTISIG),$(MULTIPROOF_CB_SENDER),base-signer.json,)

.PHONY: gen-validation-multiproof-sc
gen-validation-multiproof-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(ACTIVATE_MULTIPROOF_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(MULTIPROOF_SC_SENDER),security-council-signer.json,)

.PHONY: approve-multiproof-cb
approve-multiproof-cb: SCRIPT_NAME := $(ACTIVATE_MULTIPROOF_SCRIPT_NAME)
approve-multiproof-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-multiproof-sc
approve-multiproof-sc: SCRIPT_NAME := $(ACTIVATE_MULTIPROOF_SCRIPT_NAME)
approve-multiproof-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-activate-multiproof
execute-activate-multiproof: SCRIPT_NAME := $(ACTIVATE_MULTIPROOF_SCRIPT_NAME)
execute-activate-multiproof:
	$(call MULTISIG_EXECUTE,0x)
