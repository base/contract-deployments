include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# NestedMultisigBuilder commands
# The following commands can be used for tasks that utilize the NestedMultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
# See more documentation on the various steps in NestedMultisigBuilder.sol.
##

# This step is run by signers on the "children" safes
.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) TransferOwner \
	--sig "sign(address)" $(CB_SIGNER_SAFE_ADDR)

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) TransferOwner \
	--sig "sign(address)" $(OP_SIGNER_SAFE_ADDR)

# This step is run once per "child" safe, and can be run by anyone (doesn't have to be a signer)
.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) TransferOwner \
	--sig "approve(address,bytes)" $(CB_SIGNER_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) TransferOwner \
	--sig "approve(address,bytes)" $(OP_SIGNER_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

# This step is run once after all children safes have approved and can be run by anyone (doesn't have to be a signer)
.PHONY: execute
execute:
	forge script --rpc-url $(L2_RPC_URL) TransferOwner \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast