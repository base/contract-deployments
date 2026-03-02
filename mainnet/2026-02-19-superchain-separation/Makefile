include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

OP_RPC_URL = https://mainnet.optimism.io
RPC_URL = $(L1_RPC_URL)

# Comma variable for use in $(call ...) arguments
COMMA := ,

# Sender addresses for validation generation
CB_NESTED_SENDER   := 0x6CD3850756b7894774Ab715D136F9dD02837De50
CB_SIGNER_SENDER   := 0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110
SC_SENDER          := 0x5ff5C78ff194acc24C22DAaDdE4D639ebF18ACC6
OP_MAINNET_SENDER  := 0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64
OP_OP_SENDER       := 0x4d494C5F61b60752D3A10062276a0eFC22596151

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

# Part 1: UpdateProxyAdminOwnerSigners
.PHONY: gen-validation-cb-1
gen-validation-cb-1: deps-signer-tool
	$(call GEN_VALIDATION,UpdateProxyAdminOwnerSigners,$(CB_NESTED_SAFE_ADDR)$(COMMA)$(CB_SIGNER_SAFE_ADDR),$(CB_NESTED_SENDER),coinbase-signer-part-1.json,)

.PHONY: gen-validation-cb-sc-1
gen-validation-cb-sc-1: deps-signer-tool
	$(call GEN_VALIDATION,UpdateProxyAdminOwnerSigners,$(CB_SC_SAFE_ADDR)$(COMMA)$(CB_SIGNER_SAFE_ADDR),$(SC_SENDER),security-council-signer-part-1.json,)

.PHONY: gen-validation-op-1
gen-validation-op-1: deps-signer-tool
	$(call GEN_VALIDATION,UpdateProxyAdminOwnerSigners,$(OP_SIGNER_SAFE_ADDR),$(OP_MAINNET_SENDER),optimism-signer.json,)

# Part 2: UpdateCBSafeSigners
# Task uses CB_SIGNER_SAFE_ADDR which will approve part 1 - needs nonce+1
.PHONY: gen-validation-cb-2
gen-validation-cb-2: deps-signer-tool
	$(eval CB_PARENT_NONCE := $(shell expr $(call GET_NONCE,$(CB_SIGNER_SAFE_ADDR)) + 1))
	$(eval CB_SIGNER_NONCE := $(shell expr $(call GET_NONCE,$(CB_NESTED_SAFE_ADDR)) + 1))
	$(call GEN_VALIDATION,UpdateCBSafeSigners,$(CB_NESTED_SAFE_ADDR),$(CB_NESTED_SENDER),coinbase-signer-part-2.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_NESTED_SAFE_ADDR))=$(CB_SIGNER_NONCE) SAFE_NONCE_$(call ADDR_UPPER,$(CB_SIGNER_SAFE_ADDR))=$(CB_PARENT_NONCE) )

# SC uses CB_SC_SAFE_ADDR which will approve part 1 - needs nonce+1
.PHONY: gen-validation-cb-sc-2
gen-validation-cb-sc-2: deps-signer-tool
	$(eval CB_PARENT_NONCE := $(shell expr $(call GET_NONCE,$(CB_SIGNER_SAFE_ADDR)) + 1))
	$(eval SC_SIGNER_NONCE := $(shell expr $(call GET_NONCE,$(CB_SC_SAFE_ADDR)) + 1))
	$(call GEN_VALIDATION,UpdateCBSafeSigners,$(CB_SC_SAFE_ADDR),$(SC_SENDER),security-council-signer-part-2.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SC_SAFE_ADDR))=$(SC_SIGNER_NONCE) SAFE_NONCE_$(call ADDR_UPPER,$(CB_SIGNER_SAFE_ADDR))=$(CB_PARENT_NONCE) )

# Part 3: UpgradeSystemConfig
# ProxyAdminOwner will execute part 1 - needs nonce+1
# CB uses CB_SIGNER_SAFE_ADDR which will approve part 1 and execute part 2 - needs nonce+2
.PHONY: gen-validation-cb-3
gen-validation-cb-3: deps-signer-tool
	$(eval PROXY_ADMIN_OWNER_NONCE := $(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + 1))
	$(eval CB_PARENT_NONCE := $(shell expr $(call GET_NONCE,$(CB_SIGNER_SAFE_ADDR)) + 2))
	$(call GEN_VALIDATION,UpgradeSystemConfig,$(CB_SIGNER_SAFE_ADDR),$(CB_SIGNER_SENDER),coinbase-signer-part-3.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SIGNER_SAFE_ADDR))=$(CB_PARENT_NONCE) SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(PROXY_ADMIN_OWNER_NONCE) )

# SC uses CB_SC_SAFE_ADDR which has Part 1 and 2 txs pending - needs nonce+2
.PHONY: gen-validation-cb-sc-3
gen-validation-cb-sc-3: deps-signer-tool
	$(eval PROXY_ADMIN_OWNER_NONCE := $(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + 1))
	$(eval SC_NONCE := $(shell expr $(call GET_NONCE,$(CB_SC_SAFE_ADDR)) + 2))
	$(call GEN_VALIDATION,UpgradeSystemConfig,$(CB_SC_SAFE_ADDR),$(SC_SENDER),security-council-signer-part-3.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SC_SAFE_ADDR))=$(SC_NONCE) SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(PROXY_ADMIN_OWNER_NONCE) )

# Part 4: UpgradeFeeDisburser
# Uses CB_NESTED_SAFE_ADDR which has Part 1 and 2 txs pending - needs nonce+2
.PHONY: gen-validation-cb-4
gen-validation-cb-4: deps-signer-tool
	$(eval CB_NESTED_NONCE := $(shell expr $(call GET_NONCE,$(CB_NESTED_SAFE_ADDR)) + 2))
	$(call GEN_VALIDATION,UpgradeFeeDisburser,,$(CB_NESTED_SENDER),coinbase-signer-part-4.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_NESTED_SAFE_ADDR))=$(CB_NESTED_NONCE) )

# Part 5: TerminateSmartEscrow
.PHONY: gen-validation-cb-5
gen-validation-cb-5: RPC_URL = $(OP_RPC_URL)
gen-validation-cb-5: deps-signer-tool
	$(call GEN_VALIDATION,TerminateSmartEscrow,,$(CB_NESTED_SENDER),coinbase-signer-part-5.json,)

# Part 6: WithdrawSmartEscrow
# Uses CB_SAFE_ON_OP which executes part 5 - needs nonce+1
.PHONY: gen-validation-cb-6
gen-validation-cb-6: RPC_URL = $(OP_RPC_URL)
gen-validation-cb-6: deps-signer-tool
	$(eval CB_NONCE := $(shell expr $(call GET_NONCE,$(CB_SAFE_ON_OP)) + 1))
	$(call GEN_VALIDATION,WithdrawSmartEscrow,$(CB_SAFE_ON_OP),$(CB_NESTED_SENDER),coinbase-signer-part-6.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SAFE_ON_OP))=$(CB_NONCE) )

.PHONY: gen-validation-op-2
gen-validation-op-2: RPC_URL = $(OP_RPC_URL)
gen-validation-op-2: deps-signer-tool
	$(call GEN_VALIDATION,WithdrawSmartEscrow,$(OP_SAFE_ON_OP),$(OP_OP_SENDER),optimism-op-mainnet-signer.json,)

# Part 7: AddSecurityCouncilSigner
# Uses CB_SIGNER_SAFE_ADDR which will approve part 1, 2 and 3 - needs nonce+3
.PHONY: gen-validation-cb-sc-4
gen-validation-cb-sc-4: deps-signer-tool
	$(eval SC_NONCE := $(shell expr $(call GET_NONCE,$(CB_SC_SAFE_ADDR)) + 3))
	$(call GEN_VALIDATION,AddSecurityCouncilSigner,,$(SC_SENDER),security-council-signer-part-4.json,SAFE_NONCE_$(call ADDR_UPPER,$(CB_SC_SAFE_ADDR))=$(SC_NONCE) )

##
# Deployments
##
.PHONY: deploy-fee-disburser
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

.PHONY: deploy-l1-contracts
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
# Approvals - UpdateProxyAdminOwnerSigners
##
.PHONY: approve-proxyadminowner-signers-cb
approve-proxyadminowner-signers-cb:
	SCRIPT_NAME=UpdateProxyAdminOwnerSigners $(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-proxyadminowner-signers-sc
approve-proxyadminowner-signers-sc:
	SCRIPT_NAME=UpdateProxyAdminOwnerSigners $(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-proxyadminowner-signers-op
approve-proxyadminowner-signers-op:
	SCRIPT_NAME=UpdateProxyAdminOwnerSigners $(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-proxyadminowner-signers-cb-coord
approve-proxyadminowner-signers-cb-coord:
	SCRIPT_NAME=UpdateProxyAdminOwnerSigners $(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),0x)

##
# Approvals - UpdateCBSafeSigners
##
.PHONY: approve-cbsafesigners-cb
approve-cbsafesigners-cb:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cbsafesigners-sc
approve-cbsafesigners-sc:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR),$(SIGNATURES))

##
# Approvals - UpgradeSystemConfig
##
.PHONY: approve-systemconfig-cb
approve-systemconfig-cb:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-systemconfig-sc
approve-systemconfig-sc:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR),$(SIGNATURES))

##
# Approvals - WithdrawSmartEscrow
##
.PHONY: approve-withdraw-smartescrow-cb
approve-withdraw-smartescrow-cb: RPC_URL = $(OP_RPC_URL)
approve-withdraw-smartescrow-cb:
	SCRIPT_NAME=WithdrawSmartEscrow $(call MULTISIG_APPROVE,$(CB_SAFE_ON_OP),$(SIGNATURES))

.PHONY: approve-withdraw-smartescrow-op
approve-withdraw-smartescrow-op: RPC_URL = $(OP_RPC_URL)
approve-withdraw-smartescrow-op:
	SCRIPT_NAME=WithdrawSmartEscrow $(call MULTISIG_APPROVE,$(OP_SAFE_ON_OP),$(SIGNATURES))

##
# Execute
##
.PHONY: execute-proxyadminownersigners
execute-proxyadminownersigners:
	SCRIPT_NAME=UpdateProxyAdminOwnerSigners $(call MULTISIG_EXECUTE,0x)

.PHONY: execute-cbsafesigners
execute-cbsafesigners:
	SCRIPT_NAME=UpdateCBSafeSigners $(call MULTISIG_EXECUTE,0x)

.PHONY: execute-systemconfig
execute-systemconfig:
	SCRIPT_NAME=UpgradeSystemConfig $(call MULTISIG_EXECUTE,0x)

.PHONY: execute-feedisburser
execute-feedisburser:
	SCRIPT_NAME=UpgradeFeeDisburser $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-terminate-smartescrow
execute-terminate-smartescrow: RPC_URL = $(OP_RPC_URL)
execute-terminate-smartescrow:
	SCRIPT_NAME=TerminateSmartEscrow $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-withdraw-smartescrow
execute-withdraw-smartescrow: RPC_URL = $(OP_RPC_URL)
execute-withdraw-smartescrow:
	SCRIPT_NAME=WithdrawSmartEscrow $(call MULTISIG_EXECUTE,0x)

.PHONY: execute-add-signer
execute-add-signer:
	SCRIPT_NAME=AddSecurityCouncilSigner $(call MULTISIG_EXECUTE,$(SIGNATURES))
