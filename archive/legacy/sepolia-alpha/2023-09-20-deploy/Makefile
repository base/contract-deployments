include ../../Makefile
include ../.env
include .env

##
# Deploy command
##
.PHONY: deploy
deploy:
	cp deploy-config/deploy-config.json lib/optimism/packages/contracts-bedrock/deploy-config/
	cd lib/optimism/packages/contracts-bedrock && \
		forge build && \
		ETH_RPC_URL=$(L1_RPC_URL) DEPLOYMENT_CONTEXT=deploy-config IMPL_SALT=base forge script --private-key $(PRIVATE_KEY) --rpc-url $(L1_RPC_URL) Deploy --broadcast
	cp lib/optimism/packages/contracts-bedrock/deployments/deploy-config/.deploy deployed/addresses.json
