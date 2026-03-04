include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = SwitchToPermissionedGame

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(OP_SECURITY_COUNCIL_SAFE)" || (echo "OP_SECURITY_COUNCIL_SAFE required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: gen-validation
gen-validation: validate-config checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" ["$(OP_SECURITY_COUNCIL_SAFE)"] --sender $(SENDER)' --out ../validations/op-signer.json;

.PHONY: approve-op
approve-op: validate-config
	$(call MULTISIG_APPROVE,$(OP_SECURITY_COUNCIL_SAFE),$(SIGNATURES))

# Execute
.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,0x)
