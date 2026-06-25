include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
export OWNER_SAFE
export PROXY_ADMIN
export SYSTEM_CONFIG

UPGRADE_SCRIPT_NAME = script/UpgradeSystemConfig.s.sol:UpgradeSystemConfigScript
DEPLOY_SCRIPT_NAME = script/DeploySystemConfig.s.sol:DeploySystemConfigScript

BASE_SENDER = $(shell cast call $(BASE_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
OP_SENDER = $(shell cast call $(OP_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_PATCH)" || (echo "BASE_CONTRACTS_PATCH required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(PROXY_ADMIN)" || (echo "PROXY_ADMIN required" && exit 1)
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
#    │                    Base                      │       │                    OP                       │
#    │  0x646132A1667ca7aD00d36616AFBA1A28116C770A │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │
#                          └─────────────────┬───────────────────────────────────┘
#                                            ▼
#                             ┌─────────────────────────────────────────────┐
#                             │               ProxyAdminOwner               │
#                             │  0x0fe884546476dDd290eC46318785046ef68a0BA9 │
#                             └─────────────────────────────────────────────┘

##
# Validation file generation
##
.PHONY: gen-validation-base
gen-validation-base: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT_NAME),$(BASE_MULTISIG),$(BASE_SENDER),base-signer.json,OWNER_SAFE=$(OWNER_SAFE) PROXY_ADMIN=$(PROXY_ADMIN) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

.PHONY: gen-validation-op
gen-validation-op: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT_NAME),$(OP_MULTISIG),$(OP_SENDER),op-signer.json,OWNER_SAFE=$(OWNER_SAFE) PROXY_ADMIN=$(PROXY_ADMIN) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

##
# Approve
##
.PHONY: approve-base
approve-base: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
approve-base:
	$(call MULTISIG_APPROVE,$(BASE_MULTISIG),$(SIGNATURES))

.PHONY: approve-op
approve-op: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
approve-op:
	$(call MULTISIG_APPROVE,$(OP_MULTISIG),$(SIGNATURES))

##
# Execute
##
.PHONY: execute
execute: SCRIPT_NAME := $(UPGRADE_SCRIPT_NAME)
execute:
	$(call MULTISIG_EXECUTE,0x)
