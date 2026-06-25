include ../../Makefile
include ../.env
include .env

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) DeploySystemConfig --broadcast

.PHONY: upgrade
upgrade:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) UpgradeSystemConfig --broadcast

.PHONY: set-1559-params
set-1559-params:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) SetEIP1559Params --broadcast
