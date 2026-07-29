include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
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
#    │                  (3 of 6)                   │       │                 (7 of 10)                   │       │                 (5 of 7)                    │
#    │  0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110 │       │  0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd │       │  0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │                                                     │
#                          └─────────────────┬───────────────────────────────────┘                                                     │      
#                                            ▼                                                                                         │
#                             ┌─────────────────────────────────────────────┐                                                          │
#                             │                    Base                     │                                                          │
#                             │  0x9855054731540A48b28990B63DcF4f33d8AE46A1 │                                                          │
#                             └─────────────────────┬───────────────────────┘                                                          │
#                                                   │                                                                                  │
#                                                   └─────────────────┬────────────────────────────────────────────────────────────────┘
#                                                                     ▼
#                                            ┌─────────────────────────────────────────────┐
#                                            │               ProxyAdminOwner               │
#                                            │  0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c │
#                                            └─────────────────────────────────────────────┘


# OPTIMISM

.PHONY: gen-validation-op
gen-validation-op:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o OP_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(OP_MULTISIG)]" \
	--sender 0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64

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

# BASE NESTED

.PHONY: gen-validation-cb
gen-validation-cb:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o BASE_NESTED_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]" \
	--sender 0x6CD3850756b7894774Ab715D136F9dD02837De50

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]"

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_NESTED_MULTISIG), $(BASE_MULTISIG)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE SC

.PHONY: gen-validation-sc
gen-validation-sc:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o BASE_SC_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_MULTISIG), $(BASE_MULTISIG)]" \
	--sender 0x5ff5C78ff194acc24C22DAaDdE4D639ebF18ACC6

.PHONY: sign-sc
sign-sc:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_MULTISIG), $(BASE_MULTISIG)]"

.PHONY: approve-sc
approve-sc:
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