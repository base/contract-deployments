#!/usr/bin/env python3
import os, json, argparse, logging, time
from web3 import Web3
from solcx import compile_standard, install_solc

install_solc("0.8.17")
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

RPC_MAINNET = os.getenv("BASE_RPC_MAINNET", "https://mainnet.base.org")
RPC_TESTNET = os.getenv("BASE_RPC_TESTNET", "https://sepolia.base.org")
CHAIN_ID_MAINNET = 8453
CHAIN_ID_TESTNET = 84532

PRIVATE_KEY = os.getenv("PRIVATE_KEY")
ACCOUNT_ADDRESS = os.getenv("ACCOUNT_ADDRESS")

def connect_to_rpc(use_testnet=False):
    rpc = RPC_TESTNET if use_testnet else RPC_MAINNET
    w3 = Web3(Web3.HTTPProvider(rpc))
    if not w3.is_connected():
        logging.error("❌ RPC connection failed.")
        exit(1)
    chain_id = w3.eth.chain_id
    logging.info(f"Connected to Base ({'Testnet' if use_testnet else 'Mainnet'}), chainId={chain_id}")
    return w3

def compile_contract(file_path):
    with open(file_path, "r") as f:
        source = f.read()
    compiled = compile_standard({
        "language": "Solidity",
        "sources": {file_path: {"content": source}},
        "settings": {"outputSelection": {"*": {"*": ["abi", "evm.bytecode.object"]}}},
    }, solc_version="0.8.17")
    name = list(compiled["contracts"][file_path].keys())[0]
    abi = compiled["contracts"][file_path][name]["abi"]
    bytecode = compiled["contracts"][file_path][name]["evm"]["bytecode"]["object"]
    return abi, bytecode

def estimate_gas_and_balance(w3, acct, txn):
    gas_est = w3.eth.estimate_gas(txn)
    gas_price = w3.eth.gas_price
    balance = w3.eth.get_balance(acct.address)
    total_cost = gas_est * gas_price
    logging.info(f"Gas estimate: {gas_est}, gasPrice: {gas_price} wei (~{w3.from_wei(total_cost, 'ether')} ETH total)")
    if balance < total_cost:
        logging.warning("⚠️ Not enough balance for deployment!")
    return gas_est, gas_price

def deploy(w3, abi, bytecode, private_key, chain_id):
    acct = w3.eth.account.from_key(private_key)
    contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    nonce = w3.eth.get_transaction_count(acct.address)
    txn = contract.constructor().build_transaction({
        "from": acct.address,
        "nonce": nonce,
        "chainId": chain_id
    })
    gas_est, gas_price = estimate_gas_and_balance(w3, acct, txn)
    txn.update({"gas": gas_est, "gasPrice": gas_price})
    signed = acct.sign_transaction(txn)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)
    logging.info(f"🚀 Transaction sent: {w3.to_hex(tx_hash)}")
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    if receipt.status == 1:
        logging.info(f"✅ Deployed successfully at {receipt.contractAddress}")
    else:
        logging.error("❌ Deployment failed.")
    report = {
        "contractAddress": receipt.contractAddress,
        "txHash": w3.to_hex(tx_hash),
        "chainId": chain_id,
        "timestamp": int(time.time())
    }
    with open("deployment_report.json", "w") as f:
        json.dump(report, f, indent=2)
    return receipt.contractAddress

def main():
    parser = argparse.ArgumentParser(description="Deploy smart contract to Base network")
    parser.add_argument("--file", default="SimpleStorage.sol", help="Solidity contract path")
    parser.add_argument("--testnet", action="store_true", help="Deploy to Base testnet (Sepolia)")
    args = parser.parse_args()

    if not PRIVATE_KEY:
        logging.error("Please set PRIVATE_KEY in .env")
        exit(1)

    w3 = connect_to_rpc(use_testnet=args.testnet)
    abi, bytecode = compile_contract(args.file)
    chain_id = CHAIN_ID_TESTNET if args.testnet else CHAIN_ID_MAINNET
    deploy(w3, abi, bytecode, PRIVATE_KEY, chain_id)

if __name__ == "__main__":
    main()
