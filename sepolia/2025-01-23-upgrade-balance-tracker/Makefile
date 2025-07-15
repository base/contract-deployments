include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: sim-upgrade
sim-upgrade:
	forge script --rpc-url $(L1_RPC_URL) UpgradeBalanceTracker --sig "run()" -vvvv

.PHONY: upgrade
upgrade:
	forge script --rpc-url $(L1_RPC_URL) UpgradeBalanceTracker --sig "run()" --broadcast -vvvv
