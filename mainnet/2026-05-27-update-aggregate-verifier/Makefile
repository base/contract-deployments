include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))

SET_IMPL_SCRIPT_NAME = script/SetAggregateVerifierImpl.s.sol:SetAggregateVerifierImpl

CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

# Read the freshly deployed AggregateVerifier from addresses.json.
NEW_AGGREGATE_VERIFIER = $(shell jq -r '.aggregateVerifier' addresses.json)

# Env passed to forge for each phase. The script picks up
# TARGET_AGGREGATE_VERIFIER and points DGF.setImplementation at it.
UPGRADE_ENV  = TARGET_AGGREGATE_VERIFIER=$(NEW_AGGREGATE_VERIFIER)
ROLLBACK_ENV = TARGET_AGGREGATE_VERIFIER=$(OLD_AGGREGATE_VERIFIER)

# Rollback validation must simulate against post-upgrade nonces. Default = 1
# because the upgrade consumes one nonce on each safe in the nested path.
ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts-v5 && \
		cd lib/openzeppelin-contracts-v5 && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3 && rm -rf .git
	git clone --no-checkout https://github.com/Vectorized/solady.git lib/solady-v0.0.245 && \
		cd lib/solady-v0.0.245 && git checkout e0ef35adb0ccd1032794731a995cb599bba7b537 && rm -rf .git

##
# Deployment
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
# Validation generation
##
.PHONY: gen-validation-set-impl-cb
gen-validation-set-impl-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SET_IMPL_SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),coinbase-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-set-impl-sc
gen-validation-set-impl-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SET_IMPL_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))

# Rollback validation: per-safe nonce overrides so each safe gets current_nonce
# + 1 after the forward execution consumes one nonce on each.
.PHONY: gen-validation-rollback-cb
gen-validation-rollback-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SET_IMPL_SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),coinbase-signer-rollback.json,$(ROLLBACK_ENV) SAFE_NONCE_$(call ADDR_UPPER,$(PROXY_ADMIN_OWNER))=$(shell expr $(call GET_NONCE,$(PROXY_ADMIN_OWNER)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(CB_MULTISIG))=$(shell expr $(call GET_NONCE,$(CB_MULTISIG)) + $(ROLLBACK_NONCE_OFFSET)))

.PHONY: gen-validation-rollback-sc
gen-validation-rollback-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SET_IMPL_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer-rollback.json,$(ROLLBACK_ENV) SAFE_NONCE_$(call ADDR_UPPER,$(PROXY_ADMIN_OWNER))=$(shell expr $(call GET_NONCE,$(PROXY_ADMIN_OWNER)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(BASE_SECURITY_COUNCIL))=$(shell expr $(call GET_NONCE,$(BASE_SECURITY_COUNCIL)) + $(ROLLBACK_NONCE_OFFSET)))

##
# Approve & Execute (upgrade)
##
.PHONY: approve-set-impl-cb
approve-set-impl-cb: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
approve-set-impl-cb:
	$(UPGRADE_ENV) $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-set-impl-sc
approve-set-impl-sc: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
approve-set-impl-sc:
	$(UPGRADE_ENV) $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-set-impl
execute-set-impl: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
execute-set-impl:
	$(UPGRADE_ENV) $(call MULTISIG_EXECUTE,0x)

##
# Approve & Execute (rollback)
#
# THIS SHOULD ONLY BE PERFORMED IN THE EVENT THAT WE NEED TO ROLLBACK.
##
.PHONY: approve-rollback-cb
approve-rollback-cb: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
approve-rollback-cb:
	$(ROLLBACK_ENV) $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-rollback-sc
approve-rollback-sc: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
approve-rollback-sc:
	$(ROLLBACK_ENV) $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-rollback
execute-rollback: SCRIPT_NAME := $(SET_IMPL_SCRIPT_NAME)
execute-rollback:
	$(ROLLBACK_ENV) $(call MULTISIG_EXECUTE,0x)
