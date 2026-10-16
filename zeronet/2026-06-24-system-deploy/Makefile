include ../../Makefile
include ../../Multisig.mk
include ../.env

CONTRACTS_REPO := $(abspath ../../../contracts)
TASK_DIR       := $(abspath .)
DEPLOY_SCRIPT  := scripts/deploy/SystemDeploy.s.sol:SystemDeploy
SALT_MIXER     ?= salt mixer

##
# Simulation (no broadcast)
##
.PHONY: simulate
simulate:
	cd $(CONTRACTS_REPO) && \
		DEPLOY_CONFIG_PATH=$(TASK_DIR)/deploy-config/zeronet.json \
		SALT_MIXER="$(SALT_MIXER)" \
		$(MISE_EXEC) forge script -vvvv $(DEPLOY_SCRIPT) \
			--rpc-url $(L1_RPC_URL)

##
# Deployment (broadcast via Ledger)
##
.PHONY: deploy
deploy:
	cd $(CONTRACTS_REPO) && \
		DEPLOY_CONFIG_PATH=$(TASK_DIR)/deploy-config/zeronet.json \
		SALT_MIXER="$(SALT_MIXER)" \
		$(MISE_EXEC) forge script -vvvv $(DEPLOY_SCRIPT) \
			--rpc-url $(L1_RPC_URL) \
			--broadcast \
			--ledger --hd-paths $(LEDGER_HD_PATH)
