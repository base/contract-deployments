include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)

# Sender address for validation generation (parent of OWNER_SAFE)
SENDER := $(shell cast call $(OWNER_SAFE) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | head -1 | tr -d '[]' | cut -d',' -f1)

.PHONY: apply-patches
apply-patches:
	cd lib/contracts && patch -p1 < ../../patch/ifee-vault-withdraw.patch
	cd lib/contracts && patch -p1 < ../../patch/fee-disburser-semver.patch

.PHONY: deps
deps: install-eip712sign clean-lib forge-deps clone-oz-upgradeable checkout-base-contracts-commit apply-patches

##
# Deployment
##
.PHONY: deploy-fee-disburser
deploy-fee-disburser:
	forge script script/DeployFeeDisburser.s.sol:DeployFeeDisburser \
		--rpc-url $(L2_RPC_URL) \
		--broadcast \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
		-vvvv

##
# Upgrade FeeDisburser (via L1 deposit transaction)
##
.PHONY: gen-validation-upgrade
gen-validation-upgrade: deps-signer-tool
	$(call GEN_VALIDATION,UpgradeFeeDisburser,,$(SENDER),base-signer.json,)

.PHONY: execute-upgrade-feedisburser
execute-upgrade-feedisburser: SCRIPT_NAME = UpgradeFeeDisburser
execute-upgrade-feedisburser:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
