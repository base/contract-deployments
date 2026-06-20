include ../../Makefile
include ../.env
include .env

.PHONY: deploy-new-implementation
deploy-new-implementation:
	forge script --rpc-url $(OPTIMISM_RPC_URL) DeploySmartEscrow


.PHONY: verify-implementation
verify-implementation:
	forge verify-contract ${DEPLOYED_CONTRACT} SmartEscrow \
	--constructor-args $(shell cast abi-encode "constructor(address,address,address,address,address,uint256,uint256,uint256,uint256,uint256)" ${BENEFACTOR} ${BENEFICIARY} ${BENEFACTOR_OWNER} ${BENEFICIARY_OWNER} ${NESTED_SAFE} ${START} ${END} ${VESTING_PERIOD_SECONDS} ${INITIAL_TOKENS} ${VESTING_EVENT_TOKENS}) \
	--watch --chain-id $(OPTIMISM_CHAIN_ID) \
	--compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1 \
	--verifier-url https://api-optimistic.etherscan.io/api