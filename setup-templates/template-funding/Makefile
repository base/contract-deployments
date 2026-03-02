include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

# OWNER_SAFE/
# └── Signers

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = FundScript

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: sign
sign: validate-config
	$(call MULTISIG_SIGN,) --sender $(SENDER)

.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
