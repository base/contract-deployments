include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = TransferSystemConfigOwnership

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(NEW_OWNER)" || (echo "NEW_OWNER required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: gen-validation
gen-validation: deps-signer-tool run-script

.PHONY: run-script
run-script:
	mkdir -p validations; \
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),coinbase-signer.json)

.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
