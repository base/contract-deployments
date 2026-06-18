include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME = script/FixStartingAnchorRoot.s.sol:FixStartingAnchorRoot
FIX_STARTING_ANCHOR_ROOT_CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
FIX_STARTING_ANCHOR_ROOT_SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: apply-patches
apply-patches:
	cd lib/contracts && patch -p1 < ../../patch/asr-reset-anchor-game.patch

.PHONY: deps
deps: apply-patches

##
# Deployment (EOA)
##
.PHONY: deploy-anchor-state-registry
deploy-anchor-state-registry:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script --rpc-url $(L1_RPC_URL) script/DeployAnchorStateRegistry.s.sol:DeployAnchorStateRegistry \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

##
# Fix starting anchor root (multisig)
##
.PHONY: gen-validation-fix-starting-anchor-root-cb
gen-validation-fix-starting-anchor-root-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME),$(CB_MULTISIG),$(FIX_STARTING_ANCHOR_ROOT_CB_SENDER),fix-starting-anchor-root-cb-signer.json,)

.PHONY: gen-validation-fix-starting-anchor-root-sc
gen-validation-fix-starting-anchor-root-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(FIX_STARTING_ANCHOR_ROOT_SC_SENDER),fix-starting-anchor-root-sc-signer.json,)

.PHONY: approve-fix-starting-anchor-root-cb
approve-fix-starting-anchor-root-cb: SCRIPT_NAME := $(FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME)
approve-fix-starting-anchor-root-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-fix-starting-anchor-root-sc
approve-fix-starting-anchor-root-sc: SCRIPT_NAME := $(FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME)
approve-fix-starting-anchor-root-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-fix-starting-anchor-root
execute-fix-starting-anchor-root: SCRIPT_NAME := $(FIX_STARTING_ANCHOR_ROOT_SCRIPT_NAME)
execute-fix-starting-anchor-root:
	$(call MULTISIG_EXECUTE,0x)
