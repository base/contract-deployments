# MCM Mainnet Deployment

Status: EXECUTED

## Overview

This deployment initialized the Multi-Chain Manager (MCM) program on Solana mainnet to enable secure and decentralized control of Solana programs associated with the bridge infrastructure (including the Bridge program itself).

## What Was Deployed

This deployment successfully:

1. **Deployed the MCM program** to mainnet at `7w7ELBSd4F6xG7GNq6BU9cnMPpQYq8fZknsk6Jb9mszY`
2. **Initialized two multisig instances** (`0x0000000000000000000000000000000000000000000000000000000000000000` and `0x0000000000000000000000000000000000000000000000000000000000000001`) with initial temporary signer configuration
3. **Established ownership structure** where each multisig is owned by its own Authority (PDA):
- `0x0000000000000000000000000000000000000000000000000000000000000000` is owned by `DZaZMpR6ZBNPKBqaweGnoPP3QLq3pyoRTDfBpYS1QMU2`
- `0x0000000000000000000000000000000000000000000000000000000000000001` is owned by `7AoCt88ceFPCm43cj9K8w8xxWfhWRXEHZ2NGkDYNTCip`
4. **Transferred upgrade authority** of the MCM program to `DZaZMpR6ZBNPKBqaweGnoPP3QLq3pyoRTDfBpYS1QMU2`
5. **Funded the multisig authority PDAs** to enable transaction execution
