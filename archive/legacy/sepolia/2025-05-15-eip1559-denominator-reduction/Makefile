include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

MOCK_OP_NESTED=0x6AF0674791925f767060Dd52f7fB20984E8639d8
CB_COORDINATOR=0x646132A1667ca7aD00d36616AFBA1A28116C770A
CB_NESTED=0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f

#                                   +------------------+
#                                   |   Proxy Admin    |
#                                   |      Owner       |
#                                   |    (2-of-2)      |
#                                   +------------------+
#                                   /                  \
#                                  /                    \
#                                 /                      \
#                +---------------+                        +------------------+
#                |   Mock OP     |                        |        CB        |
#                |  Nested Safe  |----------------------->|    Coordinator   |
#                |    Signer     |                        |      Signer      |
#                |   (1-of-14)   |                        |     (2-of-2)     |
#                +---------------+                        +------------------+
#               /    |     |      \                              |
#              /     |     |       \                             |
#             /      |     |        \                            |
#            /       |     |         \                           |
# +---------+  +----------+   +----------+              +------------------+
# | CB EOA 1|  | CB EOA 2 |   | CB EOA 14|              |   CB Nested     |
# +---------+  +----------+   +----------+              |  Safe Signer    |
#                                                       |   (3-of-14)     |
#                                                       +------------------+
#                                                      /    |     |        \
#                                                     /     |     |         \
#                                                    /      |     |          \
#                                                   /       |     |           \
#                                          +---------+  +----------+   +----------+
#                                          | CB EOA 1|  | CB EOA 2 |   | CB EOA 14|
#                                          +---------+  +----------+   +----------+

.PHONY: sign-mock-op-nested
sign-mock-op-nested:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(MOCK_OP_NESTED)]"

.PHONY: approve-mock-op-nested
approve-mock-op-nested:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "approve(address[],bytes)" "[$(MOCK_OP_NESTED)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv


.PHONY: sign # sign-cb-nested-coordinator
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(CB_NESTED), $(CB_COORDINATOR)]"

.PHONY: approve-cb-nested-coordinator
approve-cb-nested-coordinator:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "approve(address[],bytes)" "[$(CB_NESTED), $(CB_COORDINATOR)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: sign-mock-op-nested-coordinator
sign-mock-op-nested-coordinator:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(MOCK_OP_NESTED), $(CB_COORDINATOR)]"

.PHONY: approve-mock-op-nested-coordinator
approve-mock-op-nested-coordinator:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "approve(address[],bytes)" "[$(MOCK_OP_NESTED), $(CB_COORDINATOR)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-cb-coordinator
approve-cb-coordinator:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "approve(address[],bytes)" "[$(CB_COORDINATOR)]" 0x \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
