include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: deploy-new-implementations
deploy-new-implementations:
	forge script DeployNewFeeVaultsL2 --rpc-url $(L2_RPC_URL)

.PHONY: verify-intermediate-implementations
verify-intermediate-implementations:
	@forge verify-contract ${SEQUENCER_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${L2_CHAIN_ID} --retries=1 --watch
	@forge verify-contract ${L1_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${L2_CHAIN_ID} --retries=1 --watch
	@forge verify-contract ${BASE_FEEVAULT_IMPL_INT} ./lib/base-contracts/src/fee-vault-fixes/FeeVault.sol:FeeVault --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${L2_CHAIN_ID} --retries=1 --watch

.PHONY: verify-final-implementations
verify-final-implementations: # submitted via UI since we ran into Cloudflare issues
	@forge verify-contract ${SEQUENCER_FEEVAULT_IMPL_FINAL} SequencerFeeVault --optimizer-runs=999999 --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" ${FEE_VAULT_RECIPIENT} ${MIN_WITHDRAWAL_AMOUNT} 1) --show-standard-json-input > etherscanSequencer.json
	@forge verify-contract ${L1_FEEVAULT_IMPL_FINAL} L1FeeVault --optimizer-runs=999999 --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" ${FEE_VAULT_RECIPIENT} ${MIN_WITHDRAWAL_AMOUNT} 1) --show-standard-json-input > etherscanL1.json
	@forge verify-contract ${BASE_FEEVAULT_IMPL_FINAL} BaseFeeVault --optimizer-runs=999999 --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" ${FEE_VAULT_RECIPIENT} ${MIN_WITHDRAWAL_AMOUNT} 1) --show-standard-json-input  > etherscanBase.json

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Commands for signers to run to test the nested safe
##
.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --via-ir --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "sign(address)" $(OP_SAFE_ADDR)

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --via-ir --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "sign(address)" $(CB_SAFE_ADDR)

##
# Commands for faciliators to run to test the nested safe
##

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "approve(address,bytes)" $(OP_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "approve(address,bytes)" $(CB_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast

execute:
	forge script --rpc-url $(L2_RPC_URL) FixFeeVaultsL2 \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--sender $(SENDER) --broadcast
