include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(ABSOLUTE_PRESTATE)" || (echo "ABSOLUTE_PRESTATE required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(CB_SIGNER_SAFE_ADDR)" || (echo "CB_SIGNER_SAFE_ADDR required" && exit 1)
	@test -n "$(CB_NESTED_SAFE_ADDR)" || (echo "CB_NESTED_SAFE_ADDR required" && exit 1)
	@test -n "$(CB_SC_SAFE_ADDR)" || (echo "CB_SC_SAFE_ADDR required" && exit 1)
	@test -n "$(OP_SIGNER_SAFE_ADDR)" || (echo "OP_SIGNER_SAFE_ADDR required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv


# Mainnet Commands

# OWNER_SAFE/
# ├── CB_SIGNER_SAFE_ADDR/
# │   ├── CB_NESTED_SAFE_ADDR/
# │   │   └── Signers
# │   └── CB_SC_SAFE_ADDR/
# │       └── Signers
# └── OP_SIGNER_SAFE_ADDR/
#     └── Signers

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpgradeDGF

# CB
.PHONY: sign-cb
sign-cb:
	$(call MULTISIG_SIGN,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: sign-cb-sc
sign-cb-sc:
	$(call MULTISIG_SIGN,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb-sc
approve-cb-sc:
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

# OP
.PHONY: sign-op
sign-op:
	$(call MULTISIG_SIGN,$(OP_SIGNER_SAFE_ADDR))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
