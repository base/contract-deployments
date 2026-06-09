include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpgradeBalanceTracker

##
# Deployment (EOA, run by the task engineer with a Ledger; not part of the multisig bundle).
# Writes the implementation address to addresses.json for UpgradeBalanceTracker.
##
.PHONY: deploy-balance-tracker
deploy-balance-tracker:
	$(MISE_EXEC) forge script script/DeployBalanceTracker.s.sol:DeployBalanceTracker \
		--rpc-url $(L1_RPC_URL) \
		--broadcast \
		--ledger --hd-paths $(LEDGER_HD_PATH) \
		-vvvv

##
# Generate the validation file for signers
##
.PHONY: gen-validation
gen-validation: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)

##
# Execute the upgrade once enough signatures are collected
##
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
