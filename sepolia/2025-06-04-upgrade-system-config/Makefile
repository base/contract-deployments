include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

# Overwriting this from top level makefile to change the branch
.PHONY: checkout-op-commit
checkout-op-commit:
	rm -rf lib/optimism
	mkdir -p lib/optimism
	cd lib/optimism; \
	git init; \
	git remote add origin $(OP_REPO); \
	git fetch --depth=1 origin tag $(OP_VERSION) --no-tags; \
	git checkout $(OP_VERSION); \
	git apply ../../$(OP_CONTRACT_PATCH)

.PHONY: deps
deps: new-go-deps

.PHONY: new-go-deps
new-go-deps:
	go install github.com/jackchuma/state-diff@v0.0.3

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeploySystemConfigScript --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --verify --broadcast

#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                 Base Nested                 │       │             Base Security Council           │       │                    OP                       │
#    │                  (3 of 14)                  │       │                 (1 of 14)                   │       │                 (1 of 14)                   │
#    │  0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │                                                     │
#                          └─────────────────┬───────────────────────────────────┘                                                     │      
#                                            ▼                                                                                         │
#                             ┌─────────────────────────────────────────────┐                                                          │
#                             │                    Base                     │                                                          │
#                             │  0x646132A1667ca7aD00d36616AFBA1A28116C770A │                                                          │
#                             └─────────────────────┬───────────────────────┘                                                          │
#                                                   │                                                                                  │
#                                                   └─────────────────┬────────────────────────────────────────────────────────────────┘
#                                                                     ▼
#                                            ┌─────────────────────────────────────────────┐
#                                            │               ProxyAdminOwner               │
#                                            │  0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c │
#                                            └─────────────────────────────────────────────┘

# OPTIMISM

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig  "sign(address[])" "[$(OP_MULTISIG)]"

.PHONY: gen-validation-op
gen-validation-op:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/OP_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(OP_MULTISIG)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(OP_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE NESTED

.PHONY: sign-base-nested
sign-base-nested:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]"

.PHONY: gen-validation-base-nested
gen-validation-base-nested:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/BASE_NESTED_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

.PHONY: approve-base-nested
approve-base-nested:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE SC

.PHONY: sign-base-sc
sign-base-sc:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_MULTISIG), $(BASE_MULTISIG)]"

.PHONY: gen-validation-base-sc
gen-validation-base-sc:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/BASE_SC_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_MULTISIG), $(BASE_MULTISIG)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

.PHONY: approve-base-sc
approve-base-sc:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_SC_MULTISIG), $(BASE_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE

.PHONY: approve-base
approve-base:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_MULTISIG)]" 0x \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv


# Execute

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv