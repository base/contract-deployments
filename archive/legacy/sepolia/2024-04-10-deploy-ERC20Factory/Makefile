include ../../Makefile
include ../.env
include .env

##
# Deploy command
##
.PHONY: deploy
deploy:
	forge script RunERC20FactoryDeploy --rpc-url $(L2_RPC_URL) --broadcast

.PHONY: verify
verify:
	forge verify-contract 0x6922ac4dbdfedea3a1e5535f12c3171f2b964c91 OptimismMintableERC20Factory \
	--watch --chain-id 84532 \
	--num-of-optimizations=99999 --retries=1 \
	--verifier-url 	https://sepolia-api.basescan.org/api 