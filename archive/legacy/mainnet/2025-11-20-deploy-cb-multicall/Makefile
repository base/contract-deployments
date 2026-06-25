include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

RPC_URL = $(L2_RPC_URL)

deploy:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script script/DeployCBMulticall.s.sol:DeployCBMulticallScript \
	--rpc-url ${RPC_URL} \
	--broadcast \
	--verify \
	--verifier-api-key ${VERIFIER_API_KEY} \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	-vvvv
