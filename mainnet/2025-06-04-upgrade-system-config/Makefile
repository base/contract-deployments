include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps: new-go-deps

.PHONY: new-go-deps
new-go-deps:
	go install github.com/jackchuma/state-diff@v0.0.3

L1_RPC_URL=http://127.0.0.1:8545

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

OP=0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
BASE_NESTED=0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110
BASE_SC_NESTED=0x20acf55a3dcfe07fc4cecacfa1628f788ec8a4dd
BASE=0x9855054731540A48b28990B63DcF4f33d8AE46A1

# OPTIMISM

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig  "sign(address[])" "[$(OP)]" 

.PHONY: gen-validation-op
gen-validation-op:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o OP_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(OP)]" \
	--sender 0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(OP)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE NESTED

.PHONY: sign-base-nested
sign-base-nested:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED), $(BASE)]"

.PHONY: gen-validation-base-nested
gen-validation-base-nested:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o BASE_NESTED_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_NESTED), $(BASE)]" \
	--sender 0x6CD3850756b7894774Ab715D136F9dD02837De50

.PHONY: approve-base-nested
approve-base-nested:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_NESTED), $(BASE)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE SC NESTED

.PHONY: sign-base-sc-nested
sign-base-sc-nested:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_NESTED), $(BASE)]"

.PHONY: gen-validation-base-sc-nested
gen-validation-base-sc-nested:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o BASE_SC_NESTED_VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "sign(address[])" "[$(BASE_SC_NESTED), $(BASE)]" \
	--sender 0x5ff5C78ff194acc24C22DAaDdE4D639ebF18ACC6

.PHONY: approve-base-sc-nested
approve-base-sc-nested:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE_SC_NESTED), $(BASE)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

# BASE

.PHONY: approve-base
approve-base:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfigScript \
	--sig "approve(address[],bytes)" "[$(BASE)]" 0x \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
