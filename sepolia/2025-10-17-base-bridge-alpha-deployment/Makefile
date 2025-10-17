include ../../Makefile
include ../.env
include .env

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@3666ba89cd4882e457ba0f672b1a12b74998db29

.PHONY: deploy
deploy:
	forge script DeployBridge --rpc-url $(L2_RPC_URL) \
	--sender $(shell cast wallet address --account testnet-admin) \
	--account testnet-admin --broadcast -vvvv