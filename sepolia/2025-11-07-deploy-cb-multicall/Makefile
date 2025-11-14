include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

deploy:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	forge script script/DeployCBMulticall.s.sol:DeployCBMulticallScript \
	--rpc-url ${L2_RPC_URL} \
	--broadcast \
	--verify \
	--verifier-api-key ${VERIFIER_API_KEY} \
	-i 1 \
	-vvvv