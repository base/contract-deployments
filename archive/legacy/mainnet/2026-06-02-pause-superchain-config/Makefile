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

.PHONY: sign-pause
sign-pause:
	@rm -f signatures-pause.txt
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
		$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -data "$$signing_data" > sign_output.tmp; \
		cat sign_output.tmp; \
		signer=$$(grep "^Signer:" sign_output.tmp | awk '{print $$2}'); \
		sig=$$(grep "^Signature:" sign_output.tmp | awk '{print $$2}'); \
		printf "%s," "$$signer:$$nonce:$$sig" >> signatures-pause.txt; \
		rm -f sign_output.tmp; \
	done; \
	echo "" >> signatures-pause.txt

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
