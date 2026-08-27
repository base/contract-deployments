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

BASE_CONTRACTS_COMMIT := b8e2246fd0f8ce342c574e2a783f865ea82d38d4
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
export FOUNDRY_BROADCAST := $(CURDIR)/records
DEPLOY_SCRIPT := tasks/2026-08-25-update-sepolia-balance-tracker-profit-wallet/script/DeployBalanceTracker.s.sol:DeployBalanceTracker
UPGRADE_SCRIPT := tasks/2026-08-25-update-sepolia-balance-tracker-profit-wallet/script/UpgradeBalanceTracker.s.sol:UpgradeBalanceTracker
TASK_ENV := BALANCE_TRACKER=$(BALANCE_TRACKER) \
	ADDRESSES_JSON=$(ADDRESSES_JSON)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR)/lib/contracts && $(MISE_EXEC) forge install --no-git \
		OpenZeppelin/openzeppelin-contracts-upgradeable@$(OZ_UPGRADEABLE_TAG)

.PHONY: validate-ledger-admin
validate-ledger-admin:
	@test "$$($(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))" = \
		"$$(jq -r '.proxyAdmin' $(ADDRESSES_JSON))" || \
		(echo "connected Ledger account is not PROXY_ADMIN" && exit 1)

.PHONY: validate-deployment
validate-deployment:
	@jq -e '.balanceTrackerImplementation' "$(ADDRESSES_JSON)" >/dev/null || \
		(echo "run make TASK_NETWORK=$(TASK_NETWORK) deploy first" && exit 1)

.PHONY: deploy
deploy: validate-ledger-admin
	cd $(PROJECT_DIR) && $(TASK_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --sender $$(jq -r '.proxyAdmin' $(ADDRESSES_JSON)) \
		--broadcast -vvvv

.PHONY: upgrade
upgrade: validate-ledger-admin validate-deployment
	cd $(PROJECT_DIR) && $(TASK_ENV) $(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(UPGRADE_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --sender $$(jq -r '.proxyAdmin' $(ADDRESSES_JSON)) \
		--broadcast -vvvv

.PHONY: verify-current
verify-current:
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'PROFIT_WALLET()(address)' --rpc-url $(L1_RPC_URL))" = \
		"$$(jq -r '.currentProfitWallet' $(ADDRESSES_JSON))"

.PHONY: verify
verify: validate-deployment
	@test "$$($(MISE_EXEC) cast call $(BALANCE_TRACKER) 'PROFIT_WALLET()(address)' --rpc-url $(L1_RPC_URL))" = \
		"$$(jq -r '.newProfitWallet' $(ADDRESSES_JSON))"
