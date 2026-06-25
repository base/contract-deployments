include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: transfer-l1-proxy-admin-owner
transfer-l1-proxy-admin-owner:
	@forge script TransferL1ProxyAdminOwner --private-key $(PRIVATE_KEY) --broadcast --rpc-url $(L1_RPC_URL) --sig "run()"

.PHONY: transfer-l2-proxy-admin-owner
transfer-l2-proxy-admin-owner:
	@forge script TransferL2ProxyAdminOwner --private-key $(PRIVATE_KEY) --broadcast --rpc-url $(L2_RPC_URL) --sig "run()"

.PHONY: transfer-system-config-proxy-owner
transfer-system-config-proxy-owner:
	@forge script TransferSystemConfigProxyOwner --private-key $(PRIVATE_KEY) --broadcast --rpc-url $(L1_RPC_URL) --sig "run()"

