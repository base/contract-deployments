include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK must be set on the command line, for example: make TASK_NETWORK=sepolia <target>)
endif
ifneq ($(TASK_NETWORK),sepolia)
$(error unsupported TASK_NETWORK: $(TASK_NETWORK))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

export FOUNDRY_BROADCAST := $(CURDIR)/records
SCRIPT := tasks/2026-10-06-transfer-balance-tracker-ownership/script/TransferBalanceTrackerOwnership.s.sol:TransferBalanceTrackerOwnership
TASK_ENV := BALANCE_TRACKER=$(BALANCE_TRACKER) CURRENT_ADMIN=$(CURRENT_ADMIN) NEW_ADMIN=$(NEW_ADMIN)

.PHONY: validate-ledger-admin
validate-ledger-admin:
	@test "$$($(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))" = "$(CURRENT_ADMIN)" || \
		(echo "connected Ledger account is not CURRENT_ADMIN; set LEDGER_ACCOUNT=<index>" && exit 1)

.PHONY: sim
sim:
	cd $(PROJECT_DIR) && $(TASK_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(SCRIPT) \
		--sender $(CURRENT_ADMIN) -vvvv

.PHONY: execute
execute: validate-ledger-admin
	cd $(PROJECT_DIR) && $(TASK_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --sender $(CURRENT_ADMIN) --broadcast -vvvv

.PHONY: verify
verify:
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'admin()(address)' --rpc-url $(L1_RPC_URL))" = "$(NEW_ADMIN)"
	@echo "BalanceTracker admin is $(NEW_ADMIN)"
