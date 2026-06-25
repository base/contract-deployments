include ../../Makefile
include ../.env
include .env

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@24b6bcaec94eac34524bcd0774dd6ec14dc3bf21

.PHONY: deploy
deploy:
	forge script DeployBridge --rpc-url $(L2_RPC_URL) \
	--sender $(shell cast wallet address --account testnet-admin) \
	--account testnet-admin --broadcast -vvvv
