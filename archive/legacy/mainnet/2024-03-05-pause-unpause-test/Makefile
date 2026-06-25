include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Incident response commands
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
##

# Pause OptimismPortal Commands

.PHONY: pause-portal-sign
pause-portal-sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) PausePortal --sig "sign()"

.PHONY: pause-portal-run
pause-portal-run:
	@forge script --rpc-url $(L1_RPC_URL) \
	PausePortal --sig "run(bytes)" $(PAUSE_SIGNATURES) \
	--private-key $(EXECUTOR_PRIVATE_KEY) \
	--broadcast

# Unpause OptimismPortal Commands

.PHONY: unpause-portal-sign
unpause-portal-sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UnpausePortal --sig "sign()"

.PHONY: unpause-portal-run
unpause-portal-run:
	@forge script --rpc-url $(L1_RPC_URL) \
	UnpausePortal --sig "run(bytes)" $(UNPAUSE_SIGNATURES) \
	--private-key $(EXECUTOR_PRIVATE_KEY) \
	--broadcast
