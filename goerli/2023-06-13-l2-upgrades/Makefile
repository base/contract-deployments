include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
deploy-l2:
	go run cmd/foundry_deploy_config_gen/main.go && \
	forge script --rpc-url $(L2_RPC_URL) --private-key $(PRIVATE_KEY) \
	DeployL2Implementations --broadcast \
	jq --sort-keys . unsortedl2Impls.json > inputs/addresses-l2.json && \
	rm unsortedl2Impls.json

etherscan-verify-l2-bedrock-implementations:
	forge verify-contract $(BASE_FEE_VAULT) BaseFeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x0b933fFD030d2679986560C414d26093b9d3130F 0x1bc16d674ec80000 1) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${GAS_PRICE_ORACLE} GasPriceOracle --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID) --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L1_BLOCK} L1Block --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L2_CROSS_DOMAIN_MESSENGER} L2CrossDomainMessenger --constructor-args $(shell cast abi-encode "constructor(address)" ${L1_CROSS_DOMAIN_MESSENGER_PROXY}) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L1_FEE_VAULT} L1FeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x0b933fFD030d2679986560C414d26093b9d3130F 0x1bc16d674ec80000 1) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L2_ERC721_BRIDGE} L2ERC721Bridge --constructor-args $(shell cast abi-encode "constructor(address,address)" 0x4200000000000000000000000000000000000007 0x5E0c967457347D5175bF82E8CCCC6480FCD7e568) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L2_STANDARD_BRIDGE} L2StandardBridge --constructor-args $(shell cast abi-encode "constructor(address)" 0xfA6D8Ee5BE770F84FC001D098C4bD604Fe01284a) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${L2_TO_L1_MESSAGE_PASSER} L2ToL1MessagePasser --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID) --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${OPTIMISM_MINTABLE_ERC20_FACTORY} OptimismMintableERC20Factory --constructor-args $(shell cast abi-encode "constructor(address)" 0x4200000000000000000000000000000000000010) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID) --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${OPTIMISM_MINTABLE_ERC721_FACTORY} OptimismMintableERC721Factory --constructor-args $(shell cast abi-encode "constructor(address,uint256)"  0x4200000000000000000000000000000000000014 ${L1_CHAIN_ID}) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID) --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${SEQUENCER_FEE_VAULT} SequencerFeeVault --constructor-args $(shell cast abi-encode "constructor(address,uint256,uint8)" 0x0b933fFD030d2679986560C414d26093b9d3130F 0x1bc16d674ec80000 1) --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 2
endif

l2-upgrade:
	forge script -vvvv --rpc-url $(L2_RPC_URL) \
	RunPostSherlockL2 \
	--sig "run(uint256,address)" $(L2_CHAIN_ID) $(OWNER_L2) \
	--sender $(SENDER) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
