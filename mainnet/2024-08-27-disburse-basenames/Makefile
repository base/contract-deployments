include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign-disbursement1
sign-disbursement1: 
	./parser.sh disbursement1.csv; $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) DisburseBasenames \
	--sig "sign()"

.PHONY: sign-disbursement2
sign-disbursement2: 
	./parser.sh disbursement2.csv; $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) DisburseBasenames \
	--sig "sign()"

ifeq (sign,$(firstword $(MAKECMDGOALS)))
  RUN_ARG := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARG):;@:)
endif

.PHONY: sign
sign:
	./parser.sh "disbursement$(RUN_ARG).csv"; $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) DisburseBasenames \
	--sig "signWithNonce(uint256)" $(RUN_ARG)


ifeq (execute,$(firstword $(MAKECMDGOALS)))
  RUN_ARG := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARG):;@:)
endif

.PHONY: execute
execute:
	./parser.sh "disbursement$(RUN_ARG).csv"; forge script --rpc-url $(L2_RPC_URL) DisburseBasenames \
	--sig "executeWithNonce(uint256,bytes)" $(RUN_ARG) $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast



ifndef $(GOPATH)
    GOPATH=$(shell go env GOPATH)
    export GOPATH
endif

##
# Solidity Setup
##
.PHONY: deps
deps: install-eip712sign clean-lib forge-deps checkout-base-contracts-commit parser-setup

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base-org/eip712sign@v0.0.6

.PHONY: clean-lib
clean-lib:
	rm -rf lib

.PHONY: forge-deps
forge-deps:
	forge install --no-git github.com/foundry-rs/forge-std \
		github.com/base-org/basenames@108224def286db0d904b1848b3dfd5a6accce058

.PHONY: checkout-base-contracts-commit
checkout-base-contracts-commit:
	[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	rm -rf lib/base-contracts
	mkdir -p lib/base-contracts
	cd lib/base-contracts; \
	git init; \
	git remote add origin https://github.com/base-org/contracts.git; \
	git fetch --depth=1 origin $(BASE_CONTRACTS_COMMIT); \
	git reset --hard FETCH_HEAD

.PHONY: parser-setup
parser-setup:
	chmod +x parser.sh
