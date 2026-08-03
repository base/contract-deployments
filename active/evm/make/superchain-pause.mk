SCRIPT_NAME ?= script/common/superchain/PauseSuperchainConfig.s.sol:PauseSuperchainConfig

ZERO_ADDRESS := 0x0000000000000000000000000000000000000000
SAFE_TX_TYPEHASH := 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
SAFE_TX_ABI := f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)
PAUSE_SIGNATURES_FILE ?= $(CONFIG_DIR_REL)/signatures-pause.txt
SUPERCHAIN_PAUSE_ENV = INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(INCIDENT_MULTISIG)" || (echo "INCIDENT_MULTISIG required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@test "$(RECORD_STATE_DIFF)" = "true" || (echo "RECORD_STATE_DIFF=true required" && exit 1)

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(SUPERCHAIN_PAUSE_ENV))

.PHONY: sign-pause
sign-pause: validate-config
	@rm -f "$(PAUSE_SIGNATURES_FILE)"
	@mkdir -p "$(dir $(PAUSE_SIGNATURES_FILE))"
	@set -e; \
	start_nonce_hex=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(L1_RPC_URL)); \
	start_nonce=$$($(MISE_EXEC) cast to-dec "$$start_nonce_hex"); \
	superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(L1_RPC_URL)); \
	domain_separator=$$($(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "domainSeparator()(bytes32)" --rpc-url $(L1_RPC_URL)); \
	call_data=$$($(MISE_EXEC) cast calldata "pause(address)" $(ZERO_ADDRESS)); \
	call_data_hash=$$($(MISE_EXEC) cast keccak "$$call_data"); \
	echo "Starting nonce: $$start_nonce"; \
	for i in $$(seq 0 19); do \
		nonce=$$(($$start_nonce + $$i)); \
		echo "Signing with nonce $$nonce"; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $$superchain_config 0 $$call_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		$(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -data "$$signing_data" > sign_output.tmp; \
		cat sign_output.tmp; \
		signer=$$(grep "^Signer:" sign_output.tmp | awk '{print $$2}'); \
		sig=$$(grep "^Signature:" sign_output.tmp | awk '{print $$2}'); \
		printf "%s," "$$signer:$$nonce:$$sig" >> "$(PAUSE_SIGNATURES_FILE)"; \
		rm -f sign_output.tmp; \
	done; \
	echo >> "$(PAUSE_SIGNATURES_FILE)"

.PHONY: execute-pause
execute-pause: validate-config
	$(SUPERCHAIN_PAUSE_ENV) $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: check-status
check-status:
	@superchain_config=$$($(MISE_EXEC) cast call $(SYSTEM_CONFIG) "superchainConfig()(address)" --rpc-url $(L1_RPC_URL)); \
	echo "SuperchainConfig address: $$superchain_config"; \
	$(MISE_EXEC) cast call $$superchain_config "paused(address)(bool)" $(ZERO_ADDRESS) --rpc-url $(L1_RPC_URL)

.PHONY: check-nonce
check-nonce:
	@echo "Incident Safe: $(INCIDENT_MULTISIG)"
	@$(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "nonce()(uint256)" --rpc-url $(L1_RPC_URL)
