SCRIPT_NAME := script/common/superchain/PauseSuperchainConfig.s.sol:PauseSuperchainConfig

ZERO_ADDRESS := 0x0000000000000000000000000000000000000000
SAFE_TX_TYPEHASH := 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
SAFE_TX_ABI := f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)
PAUSE_SIGNATURES_FILE := $(CURDIR)/config/$(TASK_NETWORK)/signatures-pause.txt
PAUSE_SIGNATURES_TMP := $(CURDIR)/config/$(TASK_NETWORK)/.signatures-pause.txt.tmp
PAUSE_SIGN_OUTPUT := $(CURDIR)/config/$(TASK_NETWORK)/.sign-output.tmp
SUPERCHAIN_PAUSE_ENV := RECORD_STATE_DIFF=$(RECORD_STATE_DIFF) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG)

.PHONY: validate-config
validate-config:
	$(call require_vars,validate-config,BASE_CONTRACTS_COMMIT INCIDENT_MULTISIG SYSTEM_CONFIG)
	@test "$(RECORD_STATE_DIFF)" = "true" || { echo "RECORD_STATE_DIFF=true is required"; exit 1; }

.PHONY: sign-pause
sign-pause: validate-config
	@test -x "$(GOPATH)/bin/eip712sign" || { echo "run make TASK_NETWORK=$(TASK_NETWORK) deps first"; exit 1; }
	@set -eu; \
	output="$(PAUSE_SIGNATURES_TMP)"; \
	sign_output="$(PAUSE_SIGN_OUTPUT)"; \
	rm -f "$$output" "$$sign_output"; \
	trap 'rm -f "$$output" "$$sign_output"' EXIT; \
	start_nonce_hex=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(RPC_URL)); \
	start_nonce=$$($(MISE_EXEC) cast to-dec "$$start_nonce_hex"); \
	superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(RPC_URL)); \
	domain_separator=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "domainSeparator()(bytes32)" --rpc-url $(RPC_URL)); \
	call_data=$$($(MISE_EXEC) cast calldata "pause(address)" $(ZERO_ADDRESS)); \
	call_data_hash=$$($(MISE_EXEC) cast keccak "$$call_data"); \
	echo "Starting nonce: $$start_nonce"; \
	i=0; while [ "$$i" -lt 20 ]; do \
		nonce=$$(($$start_nonce + $$i)); \
		echo "Signing with nonce $$nonce"; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $$superchain_config 0 $$call_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		$(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -data "$$signing_data" >"$$sign_output"; \
		cat "$$sign_output"; \
		signer=$$(awk '/^Signer:/ { print $$2 }' "$$sign_output"); \
		sig=$$(awk '/^Signature:/ { print $$2 }' "$$sign_output"); \
		[ -n "$$signer" ] && [ -n "$$sig" ] || { echo "invalid eip712sign output" >&2; exit 1; }; \
		printf "%s," "$$signer:$$nonce:$$sig" >>"$$output"; \
		i=$$(($$i + 1)); \
	done; \
	printf '\n' >>"$$output"; \
	mv "$$output" "$(PAUSE_SIGNATURES_FILE)"

.PHONY: execute-pause
execute-pause: validate-config
	$(call require_vars,execute-pause,SIGNATURES)
	export $(SUPERCHAIN_PAUSE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: check-status
check-status:
	@superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(RPC_URL)); \
	echo "SuperchainConfig address: $$superchain_config"; \
	$(MISE_EXEC) cast call "$$superchain_config" "paused(address)(bool)" $(ZERO_ADDRESS) --rpc-url $(RPC_URL)

.PHONY: check-nonce
check-nonce:
	@echo "Incident Safe: $(INCIDENT_MULTISIG)"
	@$(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(RPC_URL)
