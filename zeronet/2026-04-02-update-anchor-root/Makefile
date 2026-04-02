include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER := $(shell cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))
UPDATE_ANCHOR_SCRIPT_NAME = script/UpdateAnchorRoot.s.sol:UpdateAnchorRoot
UPDATE_ANCHOR_CB_SENDER := $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
UPDATE_ANCHOR_SC_SENDER := $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: apply-patches
apply-patches:
	cd lib/contracts && patch -p1 < ../../patch/asr-reset-anchor-game.patch
	cd lib/contracts && patch -p1 < ../../patch/asr-bump-reinit-version.patch

.PHONY: deps
deps: task-extra-deps apply-patches

.PHONY: task-extra-deps
task-extra-deps:
	@echo "No extra dependencies required for this task."

##
# Deployment
##
.PHONY: deploy-asr-impl
deploy-asr-impl:
	forge script --rpc-url $(L1_RPC_URL) script/DeployAnchorStateRegistryImpl.s.sol:DeployAnchorStateRegistryImpl \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv --sender $(DEPLOYER)

##
# Update Anchor Root (Multisig)
##

.PHONY: gen-validation-update-anchor-cb
gen-validation-update-anchor-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_ANCHOR_SCRIPT_NAME),$(CB_MULTISIG),$(UPDATE_ANCHOR_CB_SENDER),update-anchor-cb-signer.json,)

.PHONY: gen-validation-update-anchor-sc
gen-validation-update-anchor-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_ANCHOR_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(UPDATE_ANCHOR_SC_SENDER),update-anchor-sc-signer.json,)

.PHONY: approve-update-anchor-cb
approve-update-anchor-cb: SCRIPT_NAME := $(UPDATE_ANCHOR_SCRIPT_NAME)
approve-update-anchor-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-anchor-sc
approve-update-anchor-sc: SCRIPT_NAME := $(UPDATE_ANCHOR_SCRIPT_NAME)
approve-update-anchor-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-anchor
execute-update-anchor: SCRIPT_NAME := $(UPDATE_ANCHOR_SCRIPT_NAME)
execute-update-anchor:
	$(call MULTISIG_EXECUTE,0x)
