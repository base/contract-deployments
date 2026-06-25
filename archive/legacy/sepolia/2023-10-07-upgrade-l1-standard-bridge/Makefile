include ../../Makefile
include ../.env
include .env

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) DeployL1StandardBridgeImplementation --broadcast

.PHONY: upgrade
upgrade:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) UpgradeL1StandardBridge --broadcast
