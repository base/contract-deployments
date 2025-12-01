include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = TransferSystemConfigOwnership

# Nested Safe topology for this change
# Direct Safe: Single-level nesting (direct owner path)
DIRECT_SAFE = 0x6AF0674791925f767060Dd52f7fB20984E8639d8
# Nested Safe: Two-level nesting (inner -> outer)
NESTED_INNER_SAFE = 0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f
NESTED_OUTER_SAFE = 0x646132A1667ca7aD00d36616AFBA1A28116C770A

.PHONY: gen-validation
gen-validation: gen-validation-a gen-validation-b

.PHONY: gen-validation-a
gen-validation-a: checkout-signer-tool run-script-a

.PHONY: gen-validation-b
gen-validation-b: checkout-signer-tool run-script-b

.PHONY: run-script-a
run-script-a:
	mkdir -p validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(DIRECT_SAFE)]" --sender $(SENDER)' \
	--out ../validations/direct-safe-signer.json;

.PHONY: run-script-b
run-script-b:
	mkdir -p validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(NESTED_INNER_SAFE),$(NESTED_OUTER_SAFE)]" --sender $(SENDER)' \
	--out ../validations/nested-safe-signer.json;

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
