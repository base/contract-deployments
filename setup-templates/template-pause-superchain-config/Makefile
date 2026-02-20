include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# Get first owner from INCIDENT_SAFE
SENDER := $(shell cast call $(INCIDENT_SAFE) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | head -1 | tr -d '[]' | cut -d',' -f1)

SCRIPT_NAME=PauseSuperchainConfig

.PHONY: sign-pause
sign-pause:
	@rm -f signatures-pause.txt
	@start_nonce=$$(cast call $(INCIDENT_SAFE) "nonce()" --rpc-url $(L1_RPC_URL) | xargs printf "%d"); \
	echo "Starting nonce: $$start_nonce"; \
	for i in $$(seq 0 19); do \
		nonce=$$(($$start_nonce + $$i)); \
		echo "Signing with nonce $$nonce"; \
		SAFE_NONCE=$$nonce $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
		--sig "sign(address[])" "[]" --sender $(SENDER) | tee sign_output.tmp; \
		echo "Nonce: $$nonce" >> signatures-pause.txt; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> signatures-pause.txt || true; \
		echo "" >> signatures-pause.txt; \
		rm sign_output.tmp; \
	done

# Execute
.PHONY: execute-pause
execute-pause:
	forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv

.PHONY: check-status
check-status:
	@superchain_config=$$(cast call $(SYSTEM_CONFIG) "superchainConfig()" --rpc-url $(L1_RPC_URL)); \
	superchain_config=$$(echo $$superchain_config | sed 's/0x000000000000000000000000//'); \
	echo "SuperchainConfig address: 0x$$superchain_config"; \
	cast call 0x$$superchain_config "paused()" --rpc-url $(L1_RPC_URL)

.PHONY: check-nonce
check-nonce:
	@echo "Incident Safe: $(INCIDENT_SAFE)"
	@cast call $(INCIDENT_SAFE) "nonce()" --rpc-url $(L1_RPC_URL)
