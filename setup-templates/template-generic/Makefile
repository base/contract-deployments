include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# OWNER_SAFE/
# ├── L1_0/
# │   ├── L2_0/
# │   │   └── Signers
# │   └── L2_1/
# │       └── Signers
# └── L1_1/
#     └── Signers


RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = ExampleMultisigScript

# L2_0
.PHONY: sign-l2-0
sign-l2-0:
	$(call MULTISIG_SIGN,$(L2_0) $(L1_0))

.PHONY: approve-l2-0
approve-l2-0:
	$(call MULTISIG_APPROVE,$(L2_0) $(L1_0),$(SIGNATURES))


# L2_1
.PHONY: sign-l2-1
sign-l2-1:
	$(call MULTISIG_SIGN,$(L2_0) $(L2_1))

.PHONY: approve-l2-1
approve-l2-1:
	$(call MULTISIG_APPROVE,$(L2_0) $(L2_1),$(SIGNATURES))


# L1_0
.PHONY: approve-l1-0
approve-l1-0:
	$(call MULTISIG_APPROVE,$(L1_0),0x)


# L1_1
.PHONY: sign-l1-1
sign-l1-1:
	$(call MULTISIG_SIGN,$(L1_1))

.PHONY: approve-l1-1
approve-l1-1:
	$(call MULTISIG_APPROVE,$(L1_1),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)