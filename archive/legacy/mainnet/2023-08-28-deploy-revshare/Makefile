include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: fee-disburser-ownership-transfer
fee-disburser-ownership-transfer:
	forge script FeeDisburserOwnershipTransfer --rpc-url $(L2_RPC_URL)

.PHONY: deploy-balance-tracker
deploy-balance-tracker:
	@forge script DeployBalanceTracker --rpc-url $(L1_RPC_URL) --sig "run()"

.PHONY: deploy-fee-disburser
deploy-fee-disburser:
	@forge script DeployFeeDisburser --rpc-url $(L2_RPC_URL) --sig "run()"

.PHONY: verify-balance-tracker
verify-balance-tracker:
	forge verify-contract ${BALANCE_TRACKER_PROXY} Proxy --constructor-args $(shell cast abi-encode "constructor(address)" ${BALANCE_TRACKER_DEPLOYER}) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${BALANCE_TRACKER_CHAIN_ID} --retries=1 --etherscan-api-key ${ETHERSCAN_API_KEY} --watch 
	forge verify-contract ${BALANCE_TRACKER_IMPL} ./lib/base-contracts/src/revenue-share/BalanceTracker.sol:BalanceTracker --constructor-args $(shell cast abi-encode "constructor(address)" ${PROFIT_WALLET}) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL}  --chain-id ${BALANCE_TRACKER_CHAIN_ID} --retries=1 --watch 

.PHONY: verify-fee-disburser
verify-fee-disburser:
	forge verify-contract ${FEE_DISBURSER_IMPL} ./lib/base-contracts/src/revenue-share/FeeDisburser.sol:FeeDisburser --constructor-args $(shell cast abi-encode "constructor(address,address,uint256)" ${OPTIMISM_WALLET} ${BALANCE_TRACKER_PROXY} ${FEE_DISBURSEMENT_INTERVAL}) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${L2_CHAIN_ID} --num-of-optimizations=99999 --retries=1 --compiler-version v0.8.15+commit.e14f2714 --watch 
# forge verify-contract ${FEE_DISBURSER_PROXY} Proxy --constructor-args $(shell cast abi-encode "constructor(address)" ${FEE_DISBURSER_DEPLOYER}) --verifier ${VERIFIER} --verifier-url ${VERIFIER_URL} --chain-id ${L2_CHAIN_ID} --num-of-optimizations=99999 --retries=1 --compiler-version v0.8.15+commit.e14f2714 --watch

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# MultisigBuilder commands
# The following commands can be used for tasks that utilize the MultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
##

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script UpgradeToFeeDisburser --via-ir --rpc-url $(L2_RPC_URL) --sig "sign()"

.PHONY: execute
execute:
	@forge script UpgradeToFeeDisburser --rpc-url $(L2_RPC_URL) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast
