include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
export PROXY_ADMIN_OWNER
export L1_PROXY_ADMIN
export SYSTEM_CONFIG

UPGRADE_SCRIPT_NAME = script/UpgradeSystemConfig.s.sol:UpgradeSystemConfigScript
DEPLOY_SCRIPT_NAME = script/DeploySystemConfig.s.sol:DeploySystemConfigScript

CB_SENDER = $(shell cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_PATCH)" || (echo "BASE_CONTRACTS_PATCH required" && exit 1)
	@test -n "$(PROXY_ADMIN_OWNER)" || (echo "PROXY_ADMIN_OWNER required" && exit 1)
	@test -n "$(L1_PROXY_ADMIN)" || (echo "L1_PROXY_ADMIN required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@echo "Configuration validated successfully"

# Override deps to also apply the patch to base-contracts after checkout
.PHONY: deps
deps: clean-lib forge-deps clone-oz-upgradeable checkout-base-contracts-commit apply-patch

.PHONY: apply-patch
apply-patch:
	cd lib/contracts && git init -q && git add -A && git apply ../../$(BASE_CONTRACTS_PATCH)

##
# Deployment (EOA) — run by facilitator before collecting signatures
##
.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT_NAME) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --verify --broadcast

#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                 CB Multisig                  │       │            Base Security Council             │
#    │  0x856611ed7e07d83243b15e93f6321f2df6865852 │       │  0xC4c0aD998B5DfA4CF4B298970F21b9015a5eE7bA │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │
#                          └─────────────────┬───────────────────────────────────┘
#                                            ▼
#                             ┌─────────────────────────────────────────────┐
#                             │              ProxyAdminOwner                │
#                             │  0x3d59999977e0896ee1f8783bb8251df16fb483e9 │
#                             └─────────────────────────────────────────────┘

##
# Validation file generation
##
.PHONY: gen-validation-cb
gen-validation-cb: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

.PHONY: gen-validation-sc
gen-validation-sc: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

##
# Approve
##
.PHONY: approve-cb
approve-cb: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
approve-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

##
# Execute
##
.PHONY: execute
execute: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
execute:
	$(call MULTISIG_EXECUTE,0x)
