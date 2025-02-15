include ../../Makefile
include ../.env
include .env

##
# Deploy command
##
.PHONY: deploy-l1
deploy-l1:
	forge script --rpc-url $(L1_RPC_URL) DeployVetoer1of2 --sig "deployL1()" --broadcast -i 1 \
	--verify --verifier-url $(L1_VERIFIER_URL) --chain-id $(L1_CHAIN_ID) --etherscan-api-key $(L1_ETHERSCAN_API_KEY)