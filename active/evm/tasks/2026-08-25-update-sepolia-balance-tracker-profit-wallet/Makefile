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

ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
export FOUNDRY_BROADCAST := $(CURDIR)/records
DEPLOY_SCRIPT := tasks/2026-08-25-update-sepolia-balance-tracker-profit-wallet/script/DeployBalanceTracker.s.sol:DeployBalanceTracker
UPGRADE_SCRIPT := tasks/2026-08-25-update-sepolia-balance-tracker-profit-wallet/script/UpgradeBalanceTracker.s.sol:UpgradeBalanceTracker
TASK_ENV := BALANCE_TRACKER=$(BALANCE_TRACKER) \
	CURRENT_PROFIT_WALLET=$(CURRENT_PROFIT_WALLET) \
	NEW_PROFIT_WALLET=$(NEW_PROFIT_WALLET) \
	ADDRESSES_JSON=$(ADDRESSES_JSON)
UPGRADE_ENV := $(TASK_ENV) \
	PROXY_ADMIN=$(PROXY_ADMIN) \
	SYSTEM_ADDRESS_0=$(SYSTEM_ADDRESS_0) \
	SYSTEM_ADDRESS_1=$(SYSTEM_ADDRESS_1) \
	TARGET_BALANCE_0=$(TARGET_BALANCE_0) \
	TARGET_BALANCE_1=$(TARGET_BALANCE_1)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR)/lib/contracts && $(MISE_EXEC) forge install --no-git \
		OpenZeppelin/openzeppelin-contracts-upgradeable@$(OZ_UPGRADEABLE_TAG)

.PHONY: validate-ledger-admin
validate-ledger-admin:
	@test "$$($(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))" = "$(PROXY_ADMIN)" || \
		(echo "connected Ledger account is not PROXY_ADMIN" && exit 1)

.PHONY: validate-deployment
validate-deployment:
	@test -f "$(ADDRESSES_JSON)" || (echo "run make TASK_NETWORK=$(TASK_NETWORK) deploy first" && exit 1)
	@jq -e '.balanceTrackerImplementation' "$(ADDRESSES_JSON)" >/dev/null

.PHONY: deploy
deploy: validate-ledger-admin
	cd $(PROJECT_DIR) && $(TASK_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --sender $(PROXY_ADMIN) --broadcast -vvvv

.PHONY: upgrade
upgrade: validate-ledger-admin validate-deployment
	cd $(PROJECT_DIR) && $(UPGRADE_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(UPGRADE_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --sender $(PROXY_ADMIN) --broadcast -vvvv

.PHONY: verify-current
verify-current:
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'PROFIT_WALLET()(address)' --rpc-url $(L1_RPC_URL))" = \
		"$(CURRENT_PROFIT_WALLET)"

.PHONY: verify
verify: validate-deployment
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'PROFIT_WALLET()(address)' --rpc-url $(L1_RPC_URL))" = \
		"$(NEW_PROFIT_WALLET)"
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'systemAddresses(uint256)(address)' 0 --rpc-url $(L1_RPC_URL))" = \
		"$(SYSTEM_ADDRESS_0)"
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'systemAddresses(uint256)(address)' 1 --rpc-url $(L1_RPC_URL))" = \
		"$(SYSTEM_ADDRESS_1)"
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'targetBalances(uint256)(uint256)' 0 --rpc-url $(L1_RPC_URL) | cut -d' ' -f1)" = \
		"$(TARGET_BALANCE_0)"
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'targetBalances(uint256)(uint256)' 1 --rpc-url $(L1_RPC_URL) | cut -d' ' -f1)" = \
		"$(TARGET_BALANCE_1)"
