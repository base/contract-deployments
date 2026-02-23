include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

##
# Configuration
##
RPC_URL = $(L1_RPC_URL)

# Patch file for SystemConfig to use init version 4
OP_CONTRACT_PATCH ?= patch/init-version.patch

# Sender addresses for validation generation
CB_NESTED_SENDER   := 0x7f10098bd53519c739ca8a404afe127647d94774
CB_SIGNER_SENDER   := 0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f

##
# Phony Targets
##
.PHONY: deps-signer-tool \
        gen-all-validations \
        gen-validation-cb-1 gen-validation-cb-sc-1 \
        gen-validation-cb-2 gen-validation-cb-sc-2 \
        gen-validation-cb-3 \
        deploy-fee-disburser deploy-l1-contracts \
        approve-cbsafesigners-cb approve-cbsafesigners-sc \
        approve-systemconfig-cb approve-systemconfig-sc \
        execute-cbsafesigners execute-systemconfig execute-feedisburser

##
# Signer Tool Setup
##
deps-signer-tool: checkout-signer-tool
	cd $(SIGNER_TOOL_PATH) && npm ci

##
# Validation File Generation
##
# Generates validation files for multisig signing
# Usage: GEN_VALIDATION(script_name, safe_addr, sender, output_file, env_vars)
# Note: env_vars (5th param) is optional, used for nonce overrides when pre-signing multiple txs
define GEN_VALIDATION
	cd $(SIGNER_TOOL_PATH) && \
		bun run scripts/genValidationFile.ts \
			--rpc-url $(RPC_URL) \
			--workdir .. \
			--forge-cmd '$(5)forge script --rpc-url $(RPC_URL) $(1) --sig "sign(address[])" "[$(2)]" --sender $(3)' \
			--ledger-id $(LEDGER_ACCOUNT) \
			--out ../validations/$(4)
endef

# Helper to get current nonce for a safe
# Usage: $(call GET_NONCE,safe_address)
define GET_NONCE
$(shell cast call $(1) "nonce()" --rpc-url $(RPC_URL) | cast to-dec)
endef

# Helper to convert address to uppercase for SAFE_NONCE env var
# Usage: $(call ADDR_UPPER,safe_address)
define ADDR_UPPER
$(shell echo $(1) | tr '[:lower:]' '[:upper:]')
endef

# Part 1: UpdateCBSafeSigners
gen-validation-cb-1: deps-signer-tool
	$(call GEN_VALIDATION,UpdateCBSafeSigners,$(CB_NESTED_SAFE_ADDR),$(CB_NESTED_SENDER),coinbase-signer-part-1.json,)

gen-validation-cb-sc-1: deps-signer-tool
	$(call GEN_VALIDATION,UpdateCBSafeSigners,$(CB_SC_SAFE_ADDR),$(CB_NESTED_SENDER),security-council-signer-part-1.json,)

# Part 2: UpgradeSystemConfig
# CB uses CB_SIGNER_SAFE_ADDR which will execute part 1 - needs nonce+1
gen-validation-cb-2: deps-signer-tool
	$(eval CB_PARENT_NONCE := $(shell expr $(call GET_NONCE,$(CB_SIGNER_SAFE_ADDR)) + 1))
	$(call GEN_VALIDATION,UpgradeSystemConfig,$(CB_SIGNER_SAFE_ADDR),$(CB_SIGNER_SENDER),coinbase-signer-part-2.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SIGNER_SAFE_ADDR))=$(CB_PARENT_NONCE) )

# SC uses CB_SC_SAFE_ADDR which has Part 1 tx pending - needs nonce+1
gen-validation-cb-sc-2: deps-signer-tool
	$(eval SC_NONCE := $(shell expr $(call GET_NONCE,$(CB_SC_SAFE_ADDR)) + 1))
	@echo "Using nonce override for CB_SC_SAFE_ADDR: $(SC_NONCE)"
	$(call GEN_VALIDATION,UpgradeSystemConfig,$(CB_SC_SAFE_ADDR),$(CB_NESTED_SENDER),security-council-signer-part-2.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SC_SAFE_ADDR))=$(SC_NONCE) )

# Part 3: UpgradeFeeDisburser
# Uses CB_NESTED_SAFE_ADDR which has Part 1 tx pending - needs nonce+1
gen-validation-cb-3: deps-signer-tool
	$(eval CB_NESTED_NONCE := $(shell expr $(call GET_NONCE,$(CB_NESTED_SAFE_ADDR)) + 1))
	@echo "Using nonce override for CB_NESTED_SAFE_ADDR: $(CB_NESTED_NONCE)"
	$(call GEN_VALIDATION,UpgradeFeeDisburser,,$(CB_NESTED_SENDER),coinbase-signer-part-3.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_NESTED_SAFE_ADDR))=$(CB_NESTED_NONCE) )

##
# Deployments
##
deploy-fee-disburser:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script script/DeployFeeDisburser.s.sol:DeployFeeDisburser \
		--rpc-url $(L2_RPC_URL) \
		--broadcast \
		--verify \
		--verifier-api-key $(VERIFIER_API_KEY) \
		--ledger --hd-paths $(LEDGER_HD_PATH) \
		-vvvv

deploy-l1-contracts:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script script/DeploySuperchainConfigAndSystemConfig.s.sol:DeploySuperchainConfigAndSystemConfig \
		--rpc-url $(L1_RPC_URL) \
		--broadcast \
		--verify \
		--verifier-api-key $(VERIFIER_API_KEY) \
		--ledger --hd-paths $(LEDGER_HD_PATH) \
		-vvvv

##
# Approvals - UpdateCBSafeSigners
##
approve-cbsafesigners-cb:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR),$(SIGNATURES))

approve-cbsafesigners-sc:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR),$(SIGNATURES))

##
# Approvals - UpgradeSystemConfig
##
approve-systemconfig-cb:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

approve-systemconfig-sc:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR),$(SIGNATURES))

##
# Execute
##
execute-cbsafesigners:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_EXECUTE,0x)

execute-systemconfig:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_EXECUTE,0x)

execute-feedisburser:
	SCRIPT_NAME=UpgradeFeeDisburser $(call MULTISIG_EXECUTE,$(SIGNATURES))
