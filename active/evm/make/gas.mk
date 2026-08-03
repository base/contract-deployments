GAS_MODE ?= combined
ROLLBACK_NONCE_OFFSET ?= 1

ifeq ($(GAS_MODE),gas-only)
SCRIPT_NAME ?= script/common/gas/SetGasLimit.s.sol:SetGasLimit
GAS_UPGRADE_ENV = OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) OLD_GAS_LIMIT=$(OLD_GAS_LIMIT) NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)
GAS_ROLLBACK_ENV = OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) OLD_GAS_LIMIT=$(NEW_GAS_LIMIT) NEW_GAS_LIMIT=$(OLD_GAS_LIMIT) SAFE_NONCE=$(ROLLBACK_SAFE_NONCE) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)
else ifeq ($(GAS_MODE),combined)
SCRIPT_NAME ?= script/common/gas/IncreaseEip1559ElasticityAndIncreaseGasLimit.s.sol:IncreaseEip1559ElasticityAndIncreaseGasLimitScript
GAS_UPGRADE_ENV = OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) OLD_GAS_LIMIT=$(OLD_GAS_LIMIT) NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) OLD_ELASTICITY=$(OLD_ELASTICITY) NEW_ELASTICITY=$(NEW_ELASTICITY) OLD_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) NEW_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)
GAS_ROLLBACK_ENV = OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) OLD_GAS_LIMIT=$(NEW_GAS_LIMIT) NEW_GAS_LIMIT=$(OLD_GAS_LIMIT) OLD_ELASTICITY=$(NEW_ELASTICITY) NEW_ELASTICITY=$(OLD_ELASTICITY) OLD_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) NEW_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) SAFE_NONCE=$(ROLLBACK_SAFE_NONCE) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)
else
$(error GAS_MODE must be gas-only or combined)
endif

ROLLBACK_SAFE_NONCE ?= $(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET))

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" -a "$(OWNER_SAFE)" != "TODO" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" -a "$(SYSTEM_CONFIG)" != "TODO" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@test -n "$(OLD_GAS_LIMIT)" -a "$(OLD_GAS_LIMIT)" != "TODO" || (echo "OLD_GAS_LIMIT required" && exit 1)
	@test -n "$(NEW_GAS_LIMIT)" -a "$(NEW_GAS_LIMIT)" != "TODO" || (echo "NEW_GAS_LIMIT required" && exit 1)
	@test "$(RECORD_STATE_DIFF)" = "true" || (echo "RECORD_STATE_DIFF=true required" && exit 1)
ifeq ($(GAS_MODE),combined)
	@test -n "$(OLD_ELASTICITY)" -a "$(OLD_ELASTICITY)" != "TODO" || (echo "OLD_ELASTICITY required" && exit 1)
	@test -n "$(NEW_ELASTICITY)" -a "$(NEW_ELASTICITY)" != "TODO" || (echo "NEW_ELASTICITY required" && exit 1)
	@test -n "$(OLD_DA_FOOTPRINT_GAS_SCALAR)" -a "$(OLD_DA_FOOTPRINT_GAS_SCALAR)" != "TODO" || (echo "OLD_DA_FOOTPRINT_GAS_SCALAR required" && exit 1)
	@test -n "$(NEW_DA_FOOTPRINT_GAS_SCALAR)" -a "$(NEW_DA_FOOTPRINT_GAS_SCALAR)" != "TODO" || (echo "NEW_DA_FOOTPRINT_GAS_SCALAR required" && exit 1)
endif

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(GAS_UPGRADE_ENV))

.PHONY: gen-validation-rollback
gen-validation-rollback: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer-rollback.json,$(GAS_ROLLBACK_ENV))

.PHONY: sign-upgrade
sign-upgrade: validate-config
	$(GAS_UPGRADE_ENV) $(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -- \
		$(MISE_EXEC) forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) --sig "sign(address[])" "[]"

.PHONY: sign-rollback
sign-rollback: validate-config
	$(GAS_ROLLBACK_ENV) $(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -- \
		$(MISE_EXEC) forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) --sig "sign(address[])" "[]"

.PHONY: execute execute-upgrade execute-rollback
execute: validate-config
	$(GAS_UPGRADE_ENV) $(call MULTISIG_EXECUTE,$(SIGNATURES))

execute-upgrade: execute

execute-rollback: validate-config
	$(GAS_ROLLBACK_ENV) $(call MULTISIG_EXECUTE,$(SIGNATURES))

ifeq ($(GAS_MODE),combined)
BUILDER_HARD_CAP ?= TODO

.PHONY: da-scalar
da-scalar:
ifndef TARGET_BLOB_COUNT
	$(error TARGET_BLOB_COUNT is required)
endif
	@scalar=$$(( $(NEW_GAS_LIMIT) / ($(NEW_ELASTICITY) * $(TARGET_BLOB_COUNT) * 32000) )); \
	soft_cap=$$(( $(TARGET_BLOB_COUNT) * 32000 )); \
	echo "NEW_DA_FOOTPRINT_GAS_SCALAR=$$scalar"; \
	echo; \
	echo "| Field | Value |"; \
	echo "|-------|-------|"; \
	echo "| Gas limit | \`$(NEW_GAS_LIMIT)\` |"; \
	echo "| Elasticity | \`$(NEW_ELASTICITY)\` |"; \
	echo "| DA soft-cap blob count | \`$(TARGET_BLOB_COUNT)\` |"; \
	echo "| Calculated scalar | \`$$scalar\` |"; \
	echo "| Implied soft cap | \`$$soft_cap\` estimated DA bytes per L2 block |"; \
	echo "| Builder hard cap | \`$(BUILDER_HARD_CAP)\` estimated DA bytes per L2 block |"
endif
