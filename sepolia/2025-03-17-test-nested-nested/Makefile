include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

##
# NestedMultisigBuilder commands
# The following commands can be used for tasks that utilize the NestedMultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
# See more documentation on the various steps in NestedMultisigBuilder.sol.
##

# This step is run by signers on the "children" safes
.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "sign(address)" $(OP_SAFE)

# This step is run once per "child" safe, and can be run by anyone (doesn't have to be a signer)
.PHONY: approve
approve:
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "approve(address,bytes)" $(OP_SAFE) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# This step is run once after all children safes have approved and can be run by anyone (doesn't have to be a signer)
.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

##
# DoubleNestedMultisigBuilder commands
# The following commands can be used for tasks that utilize the DoubleNestedMultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
# See more documentation on the various steps in NestedMultisigBuilder.sol.
##

# This step is run by signers on the "children" safes
.PHONY: nested-sign-cb
nested-sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "sign(address,address)" $(CB_SAFE) $(CB_COORDINATOR)

.PHONY: nested-sign-sc
nested-sign-sc:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "sign(address,address)" $(SECURITY_COUNCIL) $(CB_COORDINATOR)

# This step is run once per "child" safe, and can be run by anyone (doesn't have to be a signer)
.PHONY: nested-approve-cb
nested-approve-cb:
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(CB_SAFE) $(CB_COORDINATOR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: nested-approve-sc
nested-approve-sc:
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(SECURITY_COUNCIL) $(CB_COORDINATOR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: nested-approve-coord
nested-approve-coord:
	forge script --rpc-url $(L1_RPC_URL) DoubleNestedIncrement \
	--sig "approveOnBehalfOfIntermediateSafe(address)" $(CB_COORDINATOR) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
