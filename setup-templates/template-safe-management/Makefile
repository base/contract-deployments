include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT = UpdateSigners

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" -a "$(OP_COMMIT)" != "TODO" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" -a "$(OWNER_SAFE)" != "TODO" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: deps
deps: new-forge-deps

.PHONY: new-forge-deps
new-forge-deps:
	forge install --no-git safe-global/safe-smart-account@186a21a74b327f17fc41217a927dea7064f74604

.PHONY: gen-validation
gen-validation: validate-config checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
