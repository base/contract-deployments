include ../../Makefile
include ../.env
include ../.env.local
include .env

.PHONY: deploy-eas
deploy-eas:
	forge script --rpc-url $(L2_RPC_URL) DeployEASImplementation

verify-eas-implementations:
	forge verify-contract ${REGISTRY_IMPL_ADDRESS} ./lib/optimism/packages/contracts-bedrock/src/EAS/SchemaRegistry.sol:SchemaRegistry --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1
	forge verify-contract ${EAS_IMPL_ADDRESS} ./lib/optimism/packages/contracts-bedrock/src/EAS/EAS.sol:EAS --verifier ${VERIFIER} --watch --chain-id $(L2_CHAIN_ID)  --verifier-url ${VERIFIER_URL} --compiler-version v0.8.15+commit.e14f2714 --num-of-optimizations=99999 --retries=1

##
# Commands for signers to run to test the nested safe
##

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --private-key ${PRIVATE_KEY} -- \
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "sign(address)" $(OP_SAFE_ADDR)

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --private-key ${PRIVATE_KEY} -- \
	forge script --via-ir --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "sign(address)" $(CB_SAFE_ADDR)

##
# Commands for facilitators to run to test the nested safe
##

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "approve(address,bytes)" $(OP_SAFE_ADDR) $(SIGNATURES) \
	--private-key ${PRIVATE_KEY} --broadcast

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "approve(address,bytes)" $(CB_SAFE_ADDR) $(SIGNATURES) \
	--private-key ${PRIVATE_KEY} --broadcast

execute:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "run()" --private-key ${PRIVATE_KEY} --broadcast
