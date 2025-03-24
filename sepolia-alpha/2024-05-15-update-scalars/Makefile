include ../../Makefile
include ../.env
include .env

# Update Gas Config command

.PHONY: update-gas-config
update-gas-config:
	@forge script --rpc-url $(L1_RPC_URL) UpdateGasConfigSepolia --private-key $(PRIVATE_KEY)  --broadcast