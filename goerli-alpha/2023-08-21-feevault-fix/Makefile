include ../../Makefile
include ../.env
include .env
include .env.local

##
# Foundry commands
##
.PHONY: deploy-new-implementations
deploy-new-implementations:
	@forge script --rpc-url $(L2_RPC_URL) DeployNewFeeVaultsL2 --sig "run(address)" ${FEE_VAULT_DEPLOYER} --private-key ${PRIVATE_KEY} --broadcast

.PHONY: verify-new-implementations
verify-new-implementations:
	@forge verify-contract ${SEQUENCER_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 
	@forge verify-contract ${L1_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 
	@forge verify-contract ${BASE_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 
	@forge verify-contract ${SEQUENCER_FEEVAULT_IMPL_FINAL} SequencerFeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x50dbbE35b5Ca1304ca6b5D043B7564172DB920e8 2000000000000000000 1) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 
	@forge verify-contract ${L1_FEEVAULT_IMPL_FINAL} L1FeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x50dbbE35b5Ca1304ca6b5D043B7564172DB920e8 2000000000000000000 1) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 
	@forge verify-contract ${BASE_FEEVAULT_IMPL_FINAL} BaseFeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x50dbbE35b5Ca1304ca6b5D043B7564172DB920e8 2000000000000000000 1) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${FEE_VAULT_CHAIN_ID} --retries=1 --watch 

.PHONY: check-fee-vaults
check-fee-vaults:
	@forge script --rpc-url $(L2_RPC_URL)  CheckFeeVaults --sig "run(address,uint256,uint8,uint256)" 0x50dbbE35b5Ca1304ca6b5D043B7564172DB920e8 2000000000000000000 1 0 -vvv

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Commands for signers to run to test the nested safe
##
.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --private-key ${PRIVATE_KEY} -- \
	forge script --via-ir --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "sign(address)" $(OP_SAFE_ADDR)

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --private-key ${PRIVATE_KEY} -- \
	forge script --via-ir --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "sign(address)" $(CB_SAFE_ADDR)

##
# Commands for facilitators to run to test the nested safe
##

.PHONY: approve-op
approve-op:
	@forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "approve(address,bytes)" $(OP_SAFE_ADDR) $(SIGNATURES) \
	--private-key ${PRIVATE_KEY} --sender $(SENDER) --broadcast

.PHONY: approve-cb
approve-cb:
	@forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "approve(address,bytes)" $(CB_SAFE_ADDR) $(SIGNATURES) \
	--private-key ${PRIVATE_KEY} --sender $(SENDER) --broadcast

execute:
	@forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "run()" --private-key ${PRIVATE_KEY} --sender $(SENDER) --broadcast
