include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = OPCMCall

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR),$(CB_SIGNER_SAFE_ADDR)]" --sender $(SENDER)' --out ../validations/cb-signer.json;

# CB
.PHONY: sign-cb
sign-cb:
	$(call MULTISIG_SIGN,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: sign-cb-sc
sign-cb-sc:
	$(call MULTISIG_SIGN,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb-sc
approve-cb-sc:
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

# OP
.PHONY: sign-op
sign-op:
	$(call MULTISIG_SIGN,$(OP_SIGNER_SAFE_ADDR))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
