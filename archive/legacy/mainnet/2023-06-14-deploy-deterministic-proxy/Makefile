include ../../Makefile
include ../.env
include .env
include .env.local

##
# Foundry commands
##
.PHONY: deploy-proxy
deploy-proxy:
	forge script DeterministicProxyDeploy --rpc-url $(L2_RPC_URL) --sig "run(address,address,string)" $(DEPLOYER) $(ADMIN) $(SALT) \
	--private-key $(SIGNER_PRIVATE_KEY) --broadcast