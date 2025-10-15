# 🧱 Base Smart Contract Deployer (Python)

![Python](https://img.shields.io/badge/python-3.10-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Base](https://img.shields.io/badge/Build-On%20Base-0052FF.svg)

A simple Python CLI for deploying Solidity smart contracts on **Base** — an Ethereum L2 by Coinbase.

## ✨ Features
- Python-based, no Node.js needed
- Auto RPC connection & chainId check
- Gas estimation and balance check
- Saves deployment report (JSON)
- Supports **Base Mainnet** and **Base Sepolia Testnet**

## ⚙️ Setup
```bash
git clone https://github.com/YOURUSERNAME/base-deployer-python
cd base-deployer-python
pip install -r requirements.txt
```

Create `.env` file:
```
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
BASE_RPC_MAINNET=https://mainnet.base.org
BASE_RPC_TESTNET=https://sepolia.base.org
```

## 🚀 Usage

Deploy to **testnet**:
```bash
python deploy_base.py --testnet
```

Deploy to **mainnet**:
```bash
python deploy_base.py
```

Example output:
```
INFO: Connected to Base (Testnet), chainId=84532
INFO: Gas estimate: 168762, gasPrice: 4500000000 wei
🚀 Transaction sent: 0xabc...
✅ Deployed successfully at 0x123...
```

## 🤝 Contribute to Base Builders
Fork the [Base Build-On-Base](https://github.com/base-org/build-on-base) repo and add your project under **Community Projects**.

## 🧠 Tags
#onbase #buildonbase #l2 #ethereum #python #smartcontracts
