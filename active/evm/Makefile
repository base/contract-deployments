include ../../Makefile
include ../../Multisig.mk

TASK_ID ?= 2026-07-10-transfer-systemconfig-ownership
TASK_NETWORK ?= zeronet
TASK_DIR = tasks/$(TASK_ID)
TASK_CONFIG_DIR = $(TASK_DIR)/config/$(TASK_NETWORK)

include $(TASK_CONFIG_DIR)/network.env
include $(TASK_CONFIG_DIR)/.env

SIGNER_TOOL_PATH = $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR = $(CURDIR)/$(TASK_CONFIG_DIR)/validations
PROJECT_DIR = $(CURDIR)/$(TASK_CONFIG_DIR)
RPC_URL = $(L1_RPC_URL)

include $(TASK_CONFIG_DIR)/task.mk
