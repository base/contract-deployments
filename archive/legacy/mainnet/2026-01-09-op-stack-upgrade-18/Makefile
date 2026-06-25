include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif


RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = ExecuteOPCMScript

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0x6CD3850756b7894774Ab715D136F9dD02837De50' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/coinbase-signer.json;


.PHONY: gen-validation-cb-sc
gen-validation-cb-sc: checkout-signer-tool run-script-cb-sc

.PHONY: run-script-cb-sc
run-script-cb-sc:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SC_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0x5ff5C78ff194acc24C22DAaDdE4D639ebF18ACC6' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/security-council-signer.json;

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" \
	--sender 0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/optimism-signer.json;

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