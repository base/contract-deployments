include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = AcceptSmartEscrowOwnership

.PHONY: gen-validation
gen-validation: gen-validation-cb gen-validation-op

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SAFE)]" --sender $(CB_SIGNER)' --out ../validations/cb-signer.json;

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SAFE)]" --sender $(OP_SIGNER)' --out ../validations/op-signer.json;

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_SAFE),$(SIGNATURES))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SAFE),$(SIGNATURES))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
