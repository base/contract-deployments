include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

# Map config variables to script variables
OWNER_SAFE ?= $(INCIDENT_MULTISIG)
L1_PORTAL ?= $(OPTIMISM_PORTAL)

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = SetThreshold

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(L1_PORTAL)" || (echo "L1_PORTAL required" && exit 1)
	@test -n "$(L2_BRIDGE_VALIDATOR)" || (echo "L2_BRIDGE_VALIDATOR required" && exit 1)
	@test -n "$(NEW_THRESHOLD)" || (echo "NEW_THRESHOLD required" && exit 1)
	@echo "Configuration validated successfully"

# TODO: ensure `sender` is a signer for `OWNER_SAFE`
# NOTE: Uses bare literal `mise exec --` (not `$(MISE_EXEC)`) so the forge
# command written into validations/signer.json by state-diff stays portable
# across signer machines. See Multisig.mk's GEN_VALIDATION macro for the
# full rationale and the README's "Toolchain (mise)" section for the PATH
# requirement on the signer-tool subprocess.
.PHONY: gen-validation
gen-validation: validate-config
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/signer.json \
	-- mise exec -- forge script --rpc-url $(L1_RPC_URL) SetThreshold \
	--sig "sign(address[])" "[$(OWNER_SAFE)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

# Execute
.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
