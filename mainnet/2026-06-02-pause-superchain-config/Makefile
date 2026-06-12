include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

export INCIDENT_MULTISIG
export SYSTEM_CONFIG

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = PauseSuperchainConfig

ZERO_ADDRESS = 0x0000000000000000000000000000000000000000
SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
SAFE_TX_ABI = f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)
SIGNATURES_FILE = signatures-pause.txt
SIGN_OUTPUT_FILE = sign_output.tmp
SIGN_MAX_ATTEMPTS ?= 10
SIGN_RETRY_DELAY_SECONDS ?= 3

.PHONY: sign-pause
sign-pause:
	@set -e; \
	signatures_file="$(SIGNATURES_FILE)"; \
	sign_output_file="$(SIGN_OUTPUT_FILE)"; \
	start_nonce_hex=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(L1_RPC_URL)); \
	start_nonce=$$($(MISE_EXEC) cast to-dec "$$start_nonce_hex"); \
	superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(L1_RPC_URL)); \
	domain_separator=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "domainSeparator()(bytes32)" --rpc-url $(L1_RPC_URL)); \
	call_data=$$($(MISE_EXEC) cast calldata "pause(address)" $(ZERO_ADDRESS)); \
	call_data_hash=$$($(MISE_EXEC) cast keccak "$$call_data"); \
	if [ -s "$$signatures_file" ]; then \
		expected_nonce=$$start_nonce; \
		for existing_nonce in $$(awk -F, '{for (i = 1; i <= NF; i++) if ($$i != "") { split($$i, parts, ":"); print parts[2] }}' "$$signatures_file"); do \
			if [ "$$existing_nonce" != "$$expected_nonce" ]; then \
				echo "Existing $$signatures_file contains nonce $$existing_nonce, expected $$expected_nonce."; \
				echo "Remove $$signatures_file to start over."; \
				exit 1; \
			fi; \
			expected_nonce=$$((expected_nonce + 1)); \
		done; \
		signed_count=$$((expected_nonce - start_nonce)); \
		echo "Resuming from $$signatures_file; $$signed_count nonce(s) already signed."; \
	else \
		: > "$$signatures_file"; \
	fi; \
	echo "Starting nonce: $$start_nonce"; \
	for i in $$(seq 0 19); do \
		nonce=$$(($$start_nonce + $$i)); \
		if awk -F, -v nonce="$$nonce" '{for (i = 1; i <= NF; i++) if ($$i != "") { split($$i, parts, ":"); if (parts[2] == nonce) found = 1 }} END { exit found ? 0 : 1 }' "$$signatures_file"; then \
			echo "Skipping nonce $$nonce (already signed)"; \
			continue; \
		fi; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $$superchain_config 0 $$call_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		attempt=1; \
		while true; do \
			echo "Signing with nonce $$nonce (attempt $$attempt)"; \
			rm -f "$$sign_output_file"; \
			if $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -data "$$signing_data" > "$$sign_output_file" 2>&1; then \
				cat "$$sign_output_file"; \
				break; \
			fi; \
			cat "$$sign_output_file" || true; \
			if [ "$(SIGN_MAX_ATTEMPTS)" != "0" ] && [ "$$attempt" -ge "$(SIGN_MAX_ATTEMPTS)" ]; then \
				echo "Signing failed for nonce $$nonce after $$attempt attempt(s)."; \
				echo "Rerun make sign-pause to resume from $$signatures_file."; \
				exit 1; \
			fi; \
			echo "Signing failed for nonce $$nonce. Retrying in $(SIGN_RETRY_DELAY_SECONDS) second(s); press Ctrl-C to abort."; \
			attempt=$$((attempt + 1)); \
			sleep $(SIGN_RETRY_DELAY_SECONDS); \
		done; \
		signer=$$(grep "^Signer:" "$$sign_output_file" | awk '{print $$2}'); \
		sig=$$(grep "^Signature:" "$$sign_output_file" | awk '{print $$2}'); \
		if [ -z "$$signer" ] || [ -z "$$sig" ]; then \
			echo "Could not parse signer or signature from $$sign_output_file."; \
			exit 1; \
		fi; \
		printf "%s," "$$signer:$$nonce:$$sig" >> "$$signatures_file"; \
		rm -f "$$sign_output_file"; \
	done; \
	echo "" >> "$$signatures_file"

# Execute
.PHONY: execute-pause
execute-pause:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: check-status
check-status:
	@superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()" --rpc-url $(L1_RPC_URL)); \
	superchain_config=$$(echo $$superchain_config | sed 's/0x000000000000000000000000//'); \
	echo "SuperchainConfig address: 0x$$superchain_config"; \
	$(MISE_EXEC) cast call 0x$$superchain_config "paused()" --rpc-url $(L1_RPC_URL)

.PHONY: check-nonce
check-nonce:
	@echo "Incident Safe: $(INCIDENT_MULTISIG)"
	@$(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()" --rpc-url $(L1_RPC_URL)
