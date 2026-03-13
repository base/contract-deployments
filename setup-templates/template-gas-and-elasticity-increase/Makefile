include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

# Map config variables to script variables
OWNER_SAFE ?= $(INCIDENT_MULTISIG)

ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = IncreaseEip1559ElasticityAndIncreaseGasLimitScript

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@test -n "$(FROM_GAS_LIMIT)" -a "$(FROM_GAS_LIMIT)" != "TODO" || (echo "FROM_GAS_LIMIT required" && exit 1)
	@test -n "$(TO_GAS_LIMIT)" -a "$(TO_GAS_LIMIT)" != "TODO" || (echo "TO_GAS_LIMIT required" && exit 1)
	@test -n "$(FROM_ELASTICITY)" -a "$(FROM_ELASTICITY)" != "TODO" || (echo "FROM_ELASTICITY required" && exit 1)
	@test -n "$(TO_ELASTICITY)" -a "$(TO_ELASTICITY)" != "TODO" || (echo "TO_ELASTICITY required" && exit 1)
	@test -n "$(FROM_DA_FOOTPRINT_GAS_SCALAR)" -a "$(FROM_DA_FOOTPRINT_GAS_SCALAR)" != "TODO" || (echo "FROM_DA_FOOTPRINT_GAS_SCALAR required" && exit 1)
	@test -n "$(TO_DA_FOOTPRINT_GAS_SCALAR)" -a "$(TO_DA_FOOTPRINT_GAS_SCALAR)" != "TODO" || (echo "TO_DA_FOOTPRINT_GAS_SCALAR required" && exit 1)
	@echo "Configuration validated successfully"

# Calculate the DA footprint gas scalar based on the formula:
# da_footprint_gas_scalar = gas_limit / (elasticity * target_blob_count * 32,000)
# Uses TO_GAS_LIMIT and TO_ELASTICITY from .env
.PHONY: da-scalar
da-scalar:
ifndef TARGET_BLOB_COUNT
	$(error TARGET_BLOB_COUNT is not set. Usage: make da-scalar TARGET_BLOB_COUNT=<value>)
endif
ifeq ($(TO_GAS_LIMIT),TODO)
	$(error TO_GAS_LIMIT is not set. Please set it in .env before running this command.)
endif
ifeq ($(TO_ELASTICITY),TODO)
	$(error TO_ELASTICITY is not set. Please set it in .env before running this command.)
endif
	@echo "$(TO_GAS_LIMIT) / ($(TO_ELASTICITY) * $(TARGET_BLOB_COUNT) * 32000) ="
	@echo "TO_DA_FOOTPRINT_GAS_SCALAR=$$(( $(TO_GAS_LIMIT) / ($(TO_ELASTICITY) * $(TARGET_BLOB_COUNT) * 32000) ))"

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,NEW_GAS_LIMIT=$(TO_GAS_LIMIT) OLD_GAS_LIMIT=$(FROM_GAS_LIMIT) NEW_ELASTICITY=$(TO_ELASTICITY) OLD_ELASTICITY=$(FROM_ELASTICITY) NEW_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) OLD_DA_FOOTPRINT_GAS_SCALAR=$(FROM_DA_FOOTPRINT_GAS_SCALAR))

.PHONY: execute
execute: validate-config
	NEW_GAS_LIMIT=$(TO_GAS_LIMIT) \
	OLD_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	NEW_ELASTICITY=$(TO_ELASTICITY) \
	OLD_ELASTICITY=$(FROM_ELASTICITY) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(FROM_DA_FOOTPRINT_GAS_SCALAR) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

# Generate rollback validation file with swapped old/new values and nonce offset.
# SAFE_NONCE is set to current_nonce + ROLLBACK_NONCE_OFFSET so the rollback
# transaction targets the correct future nonce.
.PHONY: gen-validation-rollback
gen-validation-rollback: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer-rollback.json,OLD_GAS_LIMIT=$(TO_GAS_LIMIT) NEW_GAS_LIMIT=$(FROM_GAS_LIMIT) OLD_ELASTICITY=$(TO_ELASTICITY) NEW_ELASTICITY=$(FROM_ELASTICITY) OLD_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) NEW_DA_FOOTPRINT_GAS_SCALAR=$(FROM_DA_FOOTPRINT_GAS_SCALAR) SAFE_NONCE=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)))

.PHONY: execute-rollback
execute-rollback: validate-config
	OLD_GAS_LIMIT=$(TO_GAS_LIMIT) \
	NEW_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	OLD_ELASTICITY=$(TO_ELASTICITY) \
	NEW_ELASTICITY=$(FROM_ELASTICITY) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(FROM_DA_FOOTPRINT_GAS_SCALAR) \
	SAFE_NONCE=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
