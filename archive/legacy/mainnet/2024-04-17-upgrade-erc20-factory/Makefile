include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) UpgradeOptimismMintableERC20Factory \
	--sig "sign(address)" $(BASE_SAFE)

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) UpgradeOptimismMintableERC20Factory \
	--sig "sign(address)" $(OP_SAFE)


.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) UpgradeOptimismMintableERC20Factory \
	--sig "approve(address,bytes)" $(BASE_SAFE) $(SIGNATURES) \
	-i 1 --broadcast

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) UpgradeOptimismMintableERC20Factory \
	--sig "approve(address,bytes)" $(OP_SAFE) $(SIGNATURES) \
	-i 1 --broadcast

.PHONY: run
run:
	forge script --rpc-url $(L2_RPC_URL) UpgradeOptimismMintableERC20Factory \
	--sig "run()" -i 1 --broadcast