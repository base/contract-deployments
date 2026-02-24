include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpdateSystemConfigParamsScript

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) NEW_ELASTICITY=$(NEW_ELASTICITY) NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR),$(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0x7f10098BD53519c739cA8A404afE127647D94774' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/base-signer.json;

.PHONY: gen-validation-cb-sc
gen-validation-cb-sc: checkout-signer-tool run-script-cb-sc

.PHONY: run-script-cb-sc
run-script-cb-sc:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) NEW_ELASTICITY=$(NEW_ELASTICITY) NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SC_SAFE_ADDR),$(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0x7f10098BD53519c739cA8A404afE127647D94774' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/security-council-signer.json;

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) NEW_ELASTICITY=$(NEW_ELASTICITY) NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" \
	--sender 0x0CF2F86C3338993ce10F74d6f4B095712c7efe26' --ledger-id $(LEDGER_ACCOUNT) --out ../validations/optimism-signer.json;

# CB
.PHONY: approve-cb
approve-cb:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cb-sc
approve-cb-sc:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cb-coordinator
approve-cb-coordinator:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	$(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),0x)

.PHONY: approve-op
approve-op:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))
.PHONY: execute
execute:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	$(call MULTISIG_EXECUTE,0x)
