include ../../Makefile
include ../.env
include .env

# Map config variables to script variables
OWNER_SAFE ?= $(INCIDENT_MULTISIG)
L1_PORTAL ?= $(OPTIMISM_PORTAL)

# Auto-fetch SAFE_NONCE from chain if not explicitly set (e.g., via .env)
ifndef SAFE_NONCE
SAFE_NONCE := $(shell cast call $(OWNER_SAFE) "nonce()(uint256)" --rpc-url $(L1_RPC_URL) | cast to-dec)
endif
# TODO: ensure `sender` is a signer for `OWNER_SAFE`
SENDER=0x1841CB3C2ce6870D0417844C817849da64E6e937

SCRIPT_NAME=PauseBridge

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(L1_PORTAL)" || (echo "L1_PORTAL required" && exit 1)
	@test -n "$(L2_BRIDGE)" || (echo "L2_BRIDGE required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@test -n "$(SAFE_NONCE)" || (echo "SAFE_NONCE required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: gen-validation
gen-validation: validate-config checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'IS_PAUSED=true forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: sign-pause
sign-pause: validate-config
	@rm -f signatures-pause.txt
	@for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing with nonce $$nonce"; \
		IS_PAUSED=true SAFE_NONCE=$$nonce $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
		--sig "sign(address[])" "[]" --sender $(SENDER) | tee sign_output.tmp; \
		echo "Nonce: $$nonce" >> signatures-pause.txt; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> signatures-pause.txt || true; \
		echo "" >> signatures-pause.txt; \
		rm -f sign_output.tmp; \
	done

.PHONY: sign-unpause
sign-unpause: validate-config
	@rm -f signatures-unpause.txt
	@for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing with nonce $$nonce"; \
		IS_PAUSED=false SAFE_NONCE=$$nonce $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
		--sig "sign(address[])" "[]" --sender $(SENDER) | tee sign_output.tmp; \
		echo "Nonce: $$nonce" >> signatures-unpause.txt; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> signatures-unpause.txt || true; \
		echo "" >> signatures-unpause.txt; \
		rm -f sign_output.tmp; \
	done

# Execute
.PHONY: execute-pause
execute-pause: validate-config
	IS_PAUSED=true forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv

.PHONY: execute-unpause
execute-unpause: validate-config
	IS_PAUSED=false forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv

.PHONY: check-status
check-status:
	cast call $(L2_BRIDGE) "paused()" --rpc-url $(L2_RPC_URL)
