# Base Bridge Deployment

Deploys the Base side of [Base Bridge](https://github.com/base/bridge). This should be done after deploying the Solana bridge program since the program's pubkey needs to be added to `config.json`.

## Deployment Steps

1. Install dependencies

```bash
cd sepolia/2025-10-17-base-bridge-alpha-deployment
make deps
```

2. Deploy bridge

```bash
make deploy
```
