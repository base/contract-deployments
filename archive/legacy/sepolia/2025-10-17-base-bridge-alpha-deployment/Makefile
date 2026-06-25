include ../../Makefile
include ../.env
include .env

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@e9b5fe27280ad2345d823d42668810432b0651aa

.PHONY: deploy
deploy:
	forge script DeployBridge --rpc-url $(L2_RPC_URL) \
	--sender $(shell cast wallet address --account testnet-admin) \
	--account testnet-admin --broadcast -vvvv