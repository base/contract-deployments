include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address)" $(OP_SIGNER_SAFE_ADDR)

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address,bytes)" $(OP_SIGNER_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

# This step is run once after all children safes have approved and can be run by anyone (doesn't have to be a signer)
.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

##
# DoubleNestedMultisigBuilder commands
# The following commands can be used for tasks that utilize the DoubleNestedMultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
# See more documentation on the various steps in DoubleNestedMultisigBuilder.sol.
# Note: All NestedMultisigBuilder commands above can also be used with the DoubleNestedMultisigBuilder.
# In this case, we have an `ADMIN_SAFE` owned by `PARENT_SAFE`s. The `PARENT_SAFE`s are owned by `CHILD_SAFE`s.
##

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address,address)" $(CB_SIGNER_SAFE_ADDR) $(COORDINATOR_SAFE_ADDR)

.PHONY: sign-op-a
sign-op-a:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address,address)" $(OP_SIGNER_SAFE_ADDR) $(COORDINATOR_SAFE_ADDR)

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(CB_SIGNER_SAFE_ADDR) $(COORDINATOR_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-op-a
approve-op-a:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(OP_SIGNER_SAFE_ADDR) $(COORDINATOR_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-coordinator
approve-coordinator:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfIntermediateSafe(address)" $(COORDINATOR_SAFE_ADDR) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
