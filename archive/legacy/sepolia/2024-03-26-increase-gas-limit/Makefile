include ../../Makefile
include ../.env
include .env

.PHONY: update-gas-limit
update-gas-limit:
	@forge script --rpc-url $(L1_RPC_URL) UpdateGasLimitSepolia --private-key $(PRIVATE_KEY)  --broadcast
