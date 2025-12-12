include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = TransferSystemConfigOwnership

# Sepolia Commands

# OWNER_SAFE/
# ├── CB_SIGNER_SAFE_ADDR/
# │   ├── CB_NESTED_SAFE_ADDR/
# │   │   └── Signers
# │   └── CB_SC_SAFE_ADDR/
# │       └── Signers
# └── OP_SIGNER_SAFE_ADDR/
#     └── Signers

.PHONY: gen-validation
gen-validation: 
	make gen-validation-cb
	make gen-validation-cb-sc
	make gen-validation-op

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--ledger-id $(LEDGER_ACCOUNT) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR),$(CB_SIGNER_SAFE_ADDR)]" --sender $(CB_NESTED_SIGNER)' --out ../validations/coinbase-signer.json;

.PHONY: gen-validation-cb-sc
gen-validation-cb-sc: checkout-signer-tool run-script-cb-sc

.PHONY: run-script-cb-sc
run-script-cb-sc:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--ledger-id $(LEDGER_ACCOUNT) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SC_SAFE_ADDR),$(CB_SIGNER_SAFE_ADDR)]" --sender $(CB_SC_SIGNER)' --out ../validations/base-security-council-signer.json;

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--ledger-id $(LEDGER_ACCOUNT) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" --sender $(OP_SIGNER)' --out ../validations/optimism-signer.json;

# CB
.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cb-sc
approve-cb-sc:
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cb-coordinator
approve-cb-coordinator:
	$(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),0x)

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
