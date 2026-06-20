include ../../Makefile
include ../.env
include .env

##
# Incident response commands
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
##

ifndef PORTAL_GUARDIAN_PRIVATE_KEY
$(error PORTAL_GUARDIAN_PRIVATE_KEY is undefined)
endif

# Pause OptimismPortal Commands

.PHONY: pause-portal-dryrun
pause-portal-dryrun:
	@forge script --rpc-url $(L1_RPC_URL) \
	PausePortal --private-key $(PORTAL_GUARDIAN_PRIVATE_KEY)

.PHONY: pause-portal
pause-portal:
	@forge script --rpc-url $(L1_RPC_URL) \
	PausePortal --private-key $(PORTAL_GUARDIAN_PRIVATE_KEY) \
	--broadcast

# Unpause OptimismPortal Commands

.PHONY: unpause-portal-dryrun
unpause-portal-dryrun:
	@forge script --rpc-url $(L1_RPC_URL) \
	UnpausePortal --private-key $(PORTAL_GUARDIAN_PRIVATE_KEY)

.PHONY: unpause-portal
unpause-portal:
	@forge script --rpc-url $(L1_RPC_URL) \
	UnpausePortal --private-key $(PORTAL_GUARDIAN_PRIVATE_KEY) \
	--broadcast
