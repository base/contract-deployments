include ../../Makefile
include ../../Multisig.mk
-include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER ?= $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
UPGRADE_TEE_REGISTRY_SCRIPT_NAME = script/UpgradeTEEProverRegistry.s.sol:UpgradeTEEProverRegistry
UPGRADE_TEE_REGISTRY_SENDER ?= $(shell cast call $(PROXY_ADMIN_OWNER) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

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
# Deployment and setup (EOA)
##
.PHONY: deploy-and-setup
deploy-and-setup:
	forge script --rpc-url $(L1_RPC_URL) script/DeployAndSetupNitroAndTEEImpl.s.sol:DeployAndSetupNitroAndTEEImpl \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

##
# Upgrade TEEProverRegistry proxy (multisig)
##
.PHONY: gen-validation-upgrade-tee
gen-validation-upgrade-tee: deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_TEE_REGISTRY_SCRIPT_NAME),$(PROXY_ADMIN_OWNER),$(UPGRADE_TEE_REGISTRY_SENDER),upgrade-tee-registry.json,)

.PHONY: approve-upgrade-tee
approve-upgrade-tee: SCRIPT_NAME := $(UPGRADE_TEE_REGISTRY_SCRIPT_NAME)
approve-upgrade-tee:
	$(call MULTISIG_APPROVE,$(PROXY_ADMIN_OWNER),$(SIGNATURES))

.PHONY: execute-upgrade-tee
execute-upgrade-tee: SCRIPT_NAME := $(UPGRADE_TEE_REGISTRY_SCRIPT_NAME)
execute-upgrade-tee:
	$(call MULTISIG_EXECUTE,0x)
