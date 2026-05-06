include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)

# Override deps to also apply the patch to base-contracts after checkout
.PHONY: deps
deps: install-foundry
	go install github.com/base/eip712sign@v0.0.11
	rm -rf lib
	forge install --no-git \
		github.com/foundry-rs/forge-std@0844d7e1fc5e60d77b68e469bff60265f236c398 \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 \
		github.com/Vectorized/solady@502cc1ea718e6fa73b380635ee0868b0740595f0 \
		github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9
	rm -rf lib/openzeppelin-contracts-upgradeable
	git clone --no-recurse-submodules --depth 1 --branch v4.7.3 \
		https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git \
		lib/openzeppelin-contracts-upgradeable
	rm -rf lib/openzeppelin-contracts-upgradeable/.git
	forge install --no-git github.com/base/contracts@$(BASE_CONTRACTS_COMMIT)
	cd lib/contracts && git apply ../../$(BASE_CONTRACTS_PATCH)

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeploySystemConfigScript \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --verify --broadcast

#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                    Base                      │       │                    OP                       │
#    │  0x646132A1667ca7aD00d36616AFBA1A28116C770A │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │
#                          └─────────────────┬───────────────────────────────────┘
#                                            ▼
#                             ┌─────────────────────────────────────────────┐
#                             │               ProxyAdminOwner               │
#                             │  0x0fe884546476dDd290eC46318785046ef68a0BA9 │
#                             └─────────────────────────────────────────────┘

# OPTIMISM

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig  "sign(address[])" "[$(OP_MULTISIG)]"

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(OP_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE

.PHONY: sign-base
sign-base:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_MULTISIG)]"

.PHONY: approve-base
approve-base:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# Execute

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
