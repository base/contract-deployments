include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = SwitchToPermissionedGame

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	mkdir validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" ["$(OP_SECURITY_COUNCIL_SAFE)"] --sender $(SENDER)' --out ../validations/op-signer.json;

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SECURITY_COUNCIL_SAFE),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
