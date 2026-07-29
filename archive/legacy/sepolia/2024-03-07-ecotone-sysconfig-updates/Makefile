include ../../Makefile
include ../.env
include .env

# Unpause OptimismPortal Commands

.PHONY: update-gas-config
update-gas-config:
	@forge script --rpc-url $(L1_RPC_URL) UpdateGasConfigSepolia --private-key $(PRIVATE_KEY)  --broadcast
