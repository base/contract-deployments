include ../../Makefile
include ../.env
include .env

##
# Deploy command
##
.PHONY: deploy
deploy:
	forge script RunERC20FactoryDeploy --rpc-url $(L2_RPC_URL) --broadcast --verify