include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

SIGNER_TOOL_PATH = ../../signer-tool
RPC_URL = $(L1_RPC_URL)
DEPLOYER = $(shell $(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))

UPDATE_SP1_GATEWAY_SCRIPT_NAME = script/UpdateSp1Gateway.s.sol:UpdateSp1Gateway
UPDATE_SP1_GATEWAY_CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
UPDATE_SP1_GATEWAY_SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	$(MISE_EXEC) forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	rm -rf lib/sp1-contracts/contracts/lib/openzeppelin-contracts
	mkdir -p lib/sp1-contracts/contracts/lib
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/sp1-contracts/contracts/lib/openzeppelin-contracts && \
		cd lib/sp1-contracts/contracts/lib/openzeppelin-contracts && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3 && rm -rf .git

##
# Deployment (EOA)
##
.PHONY: deploy-sp1-gateway
deploy-sp1-gateway:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) script/DeploySp1Gateway.s.sol:DeploySp1Gateway \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy-zk-verifier
deploy-zk-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) script/DeployZkVerifier.s.sol:DeployZkVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

.PHONY: deploy-aggregate-verifier
deploy-aggregate-verifier:
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) script/DeployAggregateVerifier.s.sol:DeployAggregateVerifier \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --verify \
		--verifier custom \
		--verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
		--verifier-api-key $(VERIFIER_API_KEY) \
		-vvvv --sender $(DEPLOYER)

##
# Update SP1 gateway (multisig)
##
.PHONY: gen-validation-update-sp1-gateway-cb
gen-validation-update-sp1-gateway-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SP1_GATEWAY_SCRIPT_NAME),$(CB_MULTISIG),$(UPDATE_SP1_GATEWAY_CB_SENDER),coinbase-signer.json,)

.PHONY: gen-validation-update-sp1-gateway-sc
gen-validation-update-sp1-gateway-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPDATE_SP1_GATEWAY_SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(UPDATE_SP1_GATEWAY_SC_SENDER),security-council-signer.json,)

.PHONY: approve-update-sp1-gateway-cb
approve-update-sp1-gateway-cb: SCRIPT_NAME := $(UPDATE_SP1_GATEWAY_SCRIPT_NAME)
approve-update-sp1-gateway-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-update-sp1-gateway-sc
approve-update-sp1-gateway-sc: SCRIPT_NAME := $(UPDATE_SP1_GATEWAY_SCRIPT_NAME)
approve-update-sp1-gateway-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute-update-sp1-gateway
execute-update-sp1-gateway: SCRIPT_NAME := $(UPDATE_SP1_GATEWAY_SCRIPT_NAME)
execute-update-sp1-gateway:
	$(call MULTISIG_EXECUTE,0x)
