include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = ExampleMultisigScript

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" -a "$(OWNER_SAFE)" != "<SET_MULTISIG_ADDRESS>" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(TARGET)" -a "$(TARGET)" != "<SET_TARGET_ADDRESS>" || (echo "TARGET required" && exit 1)
	@echo "Configuration validated successfully"

# L2_0
.PHONY: approve-l2-0
approve-l2-0:
	$(call MULTISIG_APPROVE,$(L2_0) $(L1_0),$(SIGNATURES))


# L2_1
.PHONY: approve-l2-1
approve-l2-1:
	$(call MULTISIG_APPROVE,$(L2_0) $(L2_1),$(SIGNATURES))


# L1_0
.PHONY: approve-l1-0
approve-l1-0:
	$(call MULTISIG_APPROVE,$(L1_0),0x)


# L1_1
.PHONY: approve-l1-1
approve-l1-1:
	$(call MULTISIG_APPROVE,$(L1_1),$(SIGNATURES))

# Execute
.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,0x)