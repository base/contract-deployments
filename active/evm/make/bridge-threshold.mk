SCRIPT_NAME ?= script/common/bridge/SetThreshold.s.sol:SetThreshold
OWNER_SAFE ?= $(INCIDENT_MULTISIG)
L1_PORTAL ?= $(OPTIMISM_PORTAL)
BRIDGE_THRESHOLD_ENV = OWNER_SAFE=$(OWNER_SAFE) L1_PORTAL=$(L1_PORTAL) L2_BRIDGE_VALIDATOR=$(L2_BRIDGE_VALIDATOR) NEW_THRESHOLD=$(NEW_THRESHOLD) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(L1_PORTAL)" || (echo "L1_PORTAL required" && exit 1)
	@test -n "$(L2_BRIDGE_VALIDATOR)" || (echo "L2_BRIDGE_VALIDATOR required" && exit 1)
	@test -n "$(NEW_THRESHOLD)" || (echo "NEW_THRESHOLD required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@test "$(RECORD_STATE_DIFF)" = "true" || (echo "RECORD_STATE_DIFF=true required" && exit 1)

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(BRIDGE_THRESHOLD_ENV))

.PHONY: execute
execute: validate-config
	$(BRIDGE_THRESHOLD_ENV) $(call MULTISIG_EXECUTE,$(SIGNATURES))
