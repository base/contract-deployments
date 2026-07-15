include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = script/UpdateSigners.s.sol:UpdateSigners

INCIDENT_SENDER = $(shell $(MISE_EXEC) cast call $(OWNER_SAFE) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SECURITY_COUNCIL_SENDER = $(shell $(MISE_EXEC) cast call $(SECURITY_COUNCIL_SAFE) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SECURITY_COUNCIL_SAFE)" || (echo "SECURITY_COUNCIL_SAFE required" && exit 1)

.PHONY: gen-validation
gen-validation: gen-validation-incident gen-validation-security-council

.PHONY: gen-validation-incident
gen-validation-incident: validate-config deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(INCIDENT_SENDER),base-signer.json,)

.PHONY: gen-validation-security-council
gen-validation-security-council: validate-config deps-signer-tool
	mkdir -p validations
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SECURITY_COUNCIL_SENDER),security-council-signer.json,OWNER_SAFE=$(SECURITY_COUNCIL_SAFE))

.PHONY: execute-incident
execute-incident: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-security-council
execute-security-council: validate-config
	OWNER_SAFE=$(SECURITY_COUNCIL_SAFE) $(call MULTISIG_EXECUTE,$(SIGNATURES))
