include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = TransferFeeDisburserOwnership

.PHONY: gen-validation
gen-validation: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
