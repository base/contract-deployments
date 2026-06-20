#!/bin/bash
set -e

source ../.env
source .env

payload=$(forge script --via-ir --rpc-url ${L1_RPC_URL} TransferSystemConfigOwner --sig "sign()" | tee /dev/stderr | grep -A1 vvvvvvvv | grep -v vvvvvvvv)
cd lib/base-contracts
echo "${payload}" | go run ./cmd/sign --ledger --hd-path "m/44'/60'/${LEDGER_ACCOUNT}'/0/0"
