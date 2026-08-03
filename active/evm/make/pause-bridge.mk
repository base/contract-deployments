SCRIPT_NAME ?= script/common/bridge/PauseBridge.s.sol:PauseBridge
OWNER_SAFE ?= $(INCIDENT_MULTISIG)
L1_PORTAL ?= $(OPTIMISM_PORTAL)
SAFE_NONCE ?= $(call GET_NONCE,$(OWNER_SAFE))

ZERO_ADDRESS := 0x0000000000000000000000000000000000000000
SAFE_TX_TYPEHASH := 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
SAFE_TX_ABI := f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)
PAUSE_SIGNATURES_FILE ?= $(CONFIG_DIR_REL)/signatures-pause.txt
UNPAUSE_SIGNATURES_FILE ?= $(CONFIG_DIR_REL)/signatures-unpause.txt
PAUSE_BRIDGE_ENV = OWNER_SAFE=$(OWNER_SAFE) L1_PORTAL=$(L1_PORTAL) L2_BRIDGE=$(L2_BRIDGE) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(L1_PORTAL)" || (echo "L1_PORTAL required" && exit 1)
	@test -n "$(L2_BRIDGE)" || (echo "L2_BRIDGE required" && exit 1)
	@test -n "$(SENDER)" -a "$(SENDER)" != "TODO" || (echo "SENDER required" && exit 1)
	@test "$(RECORD_STATE_DIFF)" = "true" || (echo "RECORD_STATE_DIFF=true required" && exit 1)

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(PAUSE_BRIDGE_ENV) IS_PAUSED=true)

.PHONY: sign-pause
sign-pause: validate-config
	@rm -f "$(PAUSE_SIGNATURES_FILE)"
	@mkdir -p "$(dir $(PAUSE_SIGNATURES_FILE))"
	@set -e; \
	domain_separator=$$($(MISE_EXEC) cast call $(OWNER_SAFE) "domainSeparator()(bytes32)" --rpc-url $(L1_RPC_URL)); \
	bridge_data=$$($(MISE_EXEC) cast calldata "setPaused(bool)" true); \
	portal_data=$$($(MISE_EXEC) cast calldata "depositTransaction(address,uint256,uint64,bool,bytes)" $(L2_BRIDGE) 0 100000 false $$bridge_data); \
	portal_data_hash=$$($(MISE_EXEC) cast keccak "$$portal_data"); \
	for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing pause with nonce $$nonce"; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $(L1_PORTAL) 0 $$portal_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		$(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -data "$$signing_data" > sign_output.tmp; \
		cat sign_output.tmp; \
		echo "Nonce: $$nonce" >> "$(PAUSE_SIGNATURES_FILE)"; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> "$(PAUSE_SIGNATURES_FILE)" || true; \
		echo >> "$(PAUSE_SIGNATURES_FILE)"; \
		rm -f sign_output.tmp; \
	done

.PHONY: sign-unpause
sign-unpause: validate-config
	@rm -f "$(UNPAUSE_SIGNATURES_FILE)"
	@mkdir -p "$(dir $(UNPAUSE_SIGNATURES_FILE))"
	@set -e; \
	domain_separator=$$($(MISE_EXEC) cast call $(OWNER_SAFE) "domainSeparator()(bytes32)" --rpc-url $(L1_RPC_URL)); \
	bridge_data=$$($(MISE_EXEC) cast calldata "setPaused(bool)" false); \
	portal_data=$$($(MISE_EXEC) cast calldata "depositTransaction(address,uint256,uint64,bool,bytes)" $(L2_BRIDGE) 0 100000 false $$bridge_data); \
	portal_data_hash=$$($(MISE_EXEC) cast keccak "$$portal_data"); \
	for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing unpause with nonce $$nonce"; \
		safe_tx=$$($(MISE_EXEC) cast abi-encode '$(SAFE_TX_ABI)' $(SAFE_TX_TYPEHASH) $(L1_PORTAL) 0 $$portal_data_hash 0 0 0 0 $(ZERO_ADDRESS) $(ZERO_ADDRESS) $$nonce); \
		message_hash=$$($(MISE_EXEC) cast keccak "$$safe_tx"); \
		signing_data="0x1901$${domain_separator#0x}$${message_hash#0x}"; \
		$(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -data "$$signing_data" > sign_output.tmp; \
		cat sign_output.tmp; \
		echo "Nonce: $$nonce" >> "$(UNPAUSE_SIGNATURES_FILE)"; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> "$(UNPAUSE_SIGNATURES_FILE)" || true; \
		echo >> "$(UNPAUSE_SIGNATURES_FILE)"; \
		rm -f sign_output.tmp; \
	done

.PHONY: execute-pause execute-unpause
execute-pause: validate-config
	$(PAUSE_BRIDGE_ENV) IS_PAUSED=true $(call MULTISIG_EXECUTE,$(SIGNATURES))

execute-unpause: validate-config
	$(PAUSE_BRIDGE_ENV) IS_PAUSED=false $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: check-status
check-status:
	$(MISE_EXEC) cast call $(L2_BRIDGE) "paused()(bool)" --rpc-url $(L2_RPC_URL)
