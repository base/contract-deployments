include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: validate-deploy
validate-deploy:
	forge script --rpc-url $(L1_RPC_URL) ValidateDeploy
