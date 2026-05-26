include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

# Map config variables to script variables.
# SystemConfig.owner() on Zeronet is PROXY_ADMIN_OWNER (a 2-of-2 Safe with
# CB_MULTISIG and BASE_SECURITY_COUNCIL as owners).
OWNER_SAFE ?= $(PROXY_ADMIN_OWNER)
export OWNER_SAFE

ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = IncreaseEip1559ElasticityAndIncreaseGasLimitScript

CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

# Common env vars passed to forge for the upgrade script
UPGRADE_ENV = NEW_GAS_LIMIT=$(TO_GAS_LIMIT) OLD_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	NEW_ELASTICITY=$(TO_ELASTICITY) OLD_ELASTICITY=$(FROM_ELASTICITY) \
	NEW_DENOMINATOR=$(TO_DENOMINATOR) OLD_DENOMINATOR=$(FROM_DENOMINATOR) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) OLD_DA_FOOTPRINT_GAS_SCALAR=$(FROM_DA_FOOTPRINT_GAS_SCALAR)

# Rollback param env vars — targets the rollup-config defaults instead of the
# literal zero FROM_* values because setEIP1559Params enforces denominator >= 1
# and elasticity >= 1. Nonce overrides are NOT included here; they are computed
# per-safe in each rollback target using SAFE_NONCE_<ADDR> to avoid poisoning
# other safes in the nested path.
ROLLBACK_PARAMS = OLD_GAS_LIMIT=$(TO_GAS_LIMIT) NEW_GAS_LIMIT=$(ROLLBACK_GAS_LIMIT) \
	OLD_ELASTICITY=$(TO_ELASTICITY) NEW_ELASTICITY=$(ROLLBACK_ELASTICITY) \
	OLD_DENOMINATOR=$(TO_DENOMINATOR) NEW_DENOMINATOR=$(ROLLBACK_DENOMINATOR) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(TO_DA_FOOTPRINT_GAS_SCALAR) NEW_DA_FOOTPRINT_GAS_SCALAR=$(ROLLBACK_DA_FOOTPRINT_GAS_SCALAR)

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
	@test -n "$(FROM_DENOMINATOR)" -a "$(FROM_DENOMINATOR)" != "TODO" || (echo "FROM_DENOMINATOR required" && exit 1)
	@test -n "$(TO_DENOMINATOR)" -a "$(TO_DENOMINATOR)" != "TODO" || (echo "TO_DENOMINATOR required" && exit 1)
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

##
# Validation file generation
##
.PHONY: gen-validation-cb
gen-validation-cb: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV) OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

.PHONY: gen-validation-sc
gen-validation-sc: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV) OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

# Rollback validation: per-safe nonce overrides so each safe gets current_nonce + 1
# after the forward execution consumes one nonce on each.
.PHONY: gen-validation-cb-rollback
gen-validation-cb-rollback: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer-rollback.json,$(ROLLBACK_PARAMS) OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(CB_MULTISIG))=$(shell expr $(call GET_NONCE,$(CB_MULTISIG)) + $(ROLLBACK_NONCE_OFFSET)))

.PHONY: gen-validation-sc-rollback
gen-validation-sc-rollback: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer-rollback.json,$(ROLLBACK_PARAMS) OWNER_SAFE=$(OWNER_SAFE) SYSTEM_CONFIG=$(SYSTEM_CONFIG) SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) SAFE_NONCE_$(call ADDR_UPPER,$(BASE_SECURITY_COUNCIL))=$(shell expr $(call GET_NONCE,$(BASE_SECURITY_COUNCIL)) + $(ROLLBACK_NONCE_OFFSET)))

##
# Approve
##
.PHONY: approve-cb
approve-cb: validate-config
	$(UPGRADE_ENV) \
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc: validate-config
	$(UPGRADE_ENV) \
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

##
# Execute (after both approve-cb and approve-sc have been submitted onchain)
##
.PHONY: execute
execute: validate-config
	$(UPGRADE_ENV) \
	$(call MULTISIG_EXECUTE,0x)

##
# Rollback approve
##
.PHONY: approve-cb-rollback
approve-cb-rollback: validate-config
	$(ROLLBACK_PARAMS) \
	SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) \
	SAFE_NONCE_$(call ADDR_UPPER,$(CB_MULTISIG))=$(shell expr $(call GET_NONCE,$(CB_MULTISIG)) + $(ROLLBACK_NONCE_OFFSET)) \
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc-rollback
approve-sc-rollback: validate-config
	$(ROLLBACK_PARAMS) \
	SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) \
	SAFE_NONCE_$(call ADDR_UPPER,$(BASE_SECURITY_COUNCIL))=$(shell expr $(call GET_NONCE,$(BASE_SECURITY_COUNCIL)) + $(ROLLBACK_NONCE_OFFSET)) \
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

##
# Rollback execute (after both rollback approvals have been submitted onchain)
##
.PHONY: execute-rollback
execute-rollback: validate-config
	$(ROLLBACK_PARAMS) \
	SAFE_NONCE_$(call ADDR_UPPER,$(OWNER_SAFE))=$(shell expr $(call GET_NONCE,$(OWNER_SAFE)) + $(ROLLBACK_NONCE_OFFSET)) \
	$(call MULTISIG_EXECUTE,0x)
