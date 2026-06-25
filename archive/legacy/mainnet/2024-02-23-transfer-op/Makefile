include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

install-agora:
	forge install --no-git git@github.com:voteagora/optimism-gov.git

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(OPTIMISM_RPC_URL) TransferAndDelegateOPTokens \
	--sig "sign(address)" $(CB_MULTISIG)

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(OPTIMISM_RPC_URL) TransferAndDelegateOPTokens \
	--sig "sign(address)" $(OP_MULTISIG)


.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(OPTIMISM_RPC_URL) TransferAndDelegateOPTokens \
	--sig "approve(address,bytes)" $(CB_MULTISIG) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(OPTIMISM_RPC_URL) TransferAndDelegateOPTokens \
	--sig "approve(address,bytes)" $(OP_MULTISIG) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"

.PHONY: execute
execute:
	forge script --rpc-url $(OPTIMISM_RPC_URL) TransferAndDelegateOPTokens \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"