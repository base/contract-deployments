include ../../Makefile
include ../../Multisig.mk
-include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = script/FixNitroVerifierId.s.sol:FixNitroVerifierId
SENDER ?= $(shell cast call $(TEE_PROVER_REGISTRY_OWNER) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	forge install --no-git github.com/base/op-enclave@a2d5398f04c3a8e4df929d58ee638ba4a037bfec
	forge install --no-git github.com/risc0/risc0-ethereum@a78ac4a52fe9cfa14120c3b496430f0d42e1d8d3
	forge install --no-git github.com/succinctlabs/sp1-contracts@22c4a47cd0a388cb4e25b4f2513954e4275c74ca
	git clone --no-checkout https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts-v5 && \
		cd lib/openzeppelin-contracts-v5 && git checkout dbb6104ce834628e473d2173bbc9d47f81a9eec3
	git clone --no-checkout https://github.com/Vectorized/solady.git lib/solady-v0.0.245 && \
		cd lib/solady-v0.0.245 && git checkout e0ef35adb0ccd1032794731a995cb599bba7b537

.PHONY: validate-config
validate-config:
	@test -n "$(BASE_CONTRACTS_COMMIT)" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(TEE_PROVER_REGISTRY_OWNER)" || (echo "TEE_PROVER_REGISTRY_OWNER required" && exit 1)
	@test -n "$(NITRO_ENCLAVE_VERIFIER)" || (echo "NITRO_ENCLAVE_VERIFIER required" && exit 1)
	@test -n "$(CURRENT_NITRO_ZK_VERIFIER_ID)" || (echo "CURRENT_NITRO_ZK_VERIFIER_ID required" && exit 1)
	@test -n "$(NITRO_ZK_VERIFIER_ID)" || (echo "NITRO_ZK_VERIFIER_ID required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: gen-validation
gen-validation: validate-config deps-signer-tool
	mkdir -p validations; \
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),fix-nitro-verifier-cb-signer.json,)

.PHONY: execute
execute: validate-config
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
