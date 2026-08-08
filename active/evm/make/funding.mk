SCRIPT_NAME ?= script/common/funding/Fund.s.sol:FundScript
FUNDING_JSON ?= $(CONFIG_DIR_REL)/funding.json
FUNDING_ENV = OWNER_SAFE=$(OWNER_SAFE) FUNDING_JSON=$(FUNDING_JSON) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" -a "$(OWNER_SAFE)" != "TODO" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@test "$(RECORD_STATE_DIFF)" = "true" || (echo "RECORD_STATE_DIFF=true required" && exit 1)
	@test -f "$(FUNDING_JSON)" || (echo "Missing $(FUNDING_JSON)" && exit 1)

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(FUNDING_ENV))

.PHONY: execute
execute: validate-config
	$(FUNDING_ENV) $(call MULTISIG_EXECUTE,$(SIGNATURES))
