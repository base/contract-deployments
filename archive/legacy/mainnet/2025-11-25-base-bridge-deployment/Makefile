include ../../Makefile
include ../.env
include .env

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@042f653868a85f6a25ed6b08494f3fa558d18976

.PHONY: deploy
deploy:
	forge script DeployBridge --rpc-url $(L2_RPC_URL) --sender $(SENDER) -vvvv
