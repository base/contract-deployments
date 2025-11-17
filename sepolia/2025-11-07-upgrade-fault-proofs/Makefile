include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

# Sepolia Commands

# OWNER_SAFE/
# ├── CB_SIGNER_SAFE_ADDR/
# │   ├── CB_NESTED_SAFE_ADDR/
# │   │   └── Signers
# │   └── CB_SC_SAFE_ADDR/
# │       └── Signers
# └── OP_SIGNER_SAFE_ADDR/
#     └── Signers

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpgradeWithOpSmartContractManager

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" --sender 0x7f10098bd53519c739ca8a404afe127647d94774' --out ../validations/cb-signer.json;


.PHONY: gen-validation-cb-sc
gen-validation-cb-sc: checkout-signer-tool run-script-cb-sc

.PHONY: run-script-cb-sc
run-script-cb-sc:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SC_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" --sender 0x7f10098bd53519c739ca8a404afe127647d94774' --out ../validations/cb-sc-signer.json;

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" --sender 0x0CF2F86C3338993ce10F74d6f4B095712c7efe26' --out ../validations/op-signer.json;


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
