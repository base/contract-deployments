include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Commands for transferring ownership of L1 and L2 contracts to corresponding nested multisigs
# with CB and OP as signers
##

.PHONY: sign-l1
sign-l1:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) TransferOwnerL1 --sig "sign()"

.PHONY: sign-l2
sign-l2:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) TransferOwnerL2 --sig "sign()"

.PHONY: run-l1
run-l1:
	forge script --rpc-url $(L1_RPC_URL) \
	TransferOwnerL1 --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) -vvvv --broadcast

.PHONY: run-l2
run-l2:
	forge script --rpc-url $(L2_RPC_URL) \
	TransferOwnerL2 --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) -vvvv --broadcast


.PHONY: run-local-l1
run-local-l1:
	forge script --rpc-url $(LOCAL_URL) \
	TransferOwnerL1 --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) -vvvv --broadcast

.PHONY: run-local-l2
run-local-l2:
	forge script --rpc-url $(LOCAL_URL) \
	TransferOwnerL2 --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) -vvvv --broadcast

# L1 SIGNATURES:
# 6ca1ad47d86598e4c356fd05cb0b53d54077fed5a3c0b0e3384d0ad294fbdbcc0c216cc2262a33c4b1f1cac533bfaacb000bc5958708cb85ba09e966918761481c
# 1cb7e2feab12ecf133c8a0978a6cd9322d0f9c5e1ba9e99fa1e32a4b07692b011b50b0a7ca2bd785c88dd61e2726d4d415543d336311243ec65dcbd208107fa21c
# 65375e8e94c25600fd96df681a4d0b95f5fe761f973057ffab82a9e99edd5c6637f0bd489510ea56b882f97bd37cb725dbf5e11b673c65a59d2089789cc27c9d1c
# 5de7066993f2b44fe5e948eafdcf343136bc8568bff989e3c5847ea7c9369f8275b5f0fcb7423c35dcecc01361859f9f9d9f47f61873e0d0b8bd5007f2329aee1b


# L2 SIGNATURES:
# d8991b12c271e8435510eb9e65868653319dd8ce1d2182606cbd0b4095e1623277b4602ce3533dbb17f5b2cf06c5e503bcc264c4aa2711df27ecaed1ca1e63661c
# e671d199f47e3bc12d721988266fb5fd3285a0df670f92f936d9c354227fa4756d09e4d4d9be6ffee91cc3b0736425d656200a90b8d7142956412b15e03e62261b
# 8b79ade36ecfd1063c127057d1e7832bce1bf2d7b40d28c35c6f3cf7056ce0bb0a836ba458f1db1ebd246b7f9894a96d8f548a6af4f65b1dcc5cc5192993b4071b
# 281ebc7c95ca7f3f7572275638f0c4c9766a71cbb32b9602260246340c354af02e127b85e216d4144d39fb4f191df6d38e440a13805a1999df149a8fce33fad61c
