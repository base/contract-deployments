# Bridge Mainnet Deployment

Status: EXECUTED

## Overview

This deployment initializes the Bridge and Base Relayer programs on Solana mainnet.

## What Will Be Deployed

This deployment will:

1. **Deploy the Bridge program**
2. **Deploy the Base Relayer program**
3. **Initialize both programs** with production configuration including:
   - Guardian addresses
   - EIP-1559 fee parameters
   - Gas fee receivers
4. **Fund the required accounts**:
   - The SOL vault (to guarantee it staying rent-exempt)
   - Gas fee receiver accounts
5. **Transfer the upgrade authorities** of the bridge and base relayer programs to the MCM 0 Authority 
