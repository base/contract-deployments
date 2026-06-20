## Upgrade to new system config with 400m max gas limit

Base is continuing to scale and we need higher block gas limit to support the increased demand.

### Steps

1. pull main branch of https://github.com/base-org/contract-deployments:
`git clone git@github.com:base-org/contract-deployments.git`

2. ledger needs to be connected and unlocked
3. deploying contracts (base team):
```shell
cd sepolia/2024-12-06-increase-max-gas-limit
make deps
make deploy
```

4. sign
```shell
cd sepolia/2024-12-06-increase-max-gas-limit
make deps # skip if already installed
make sign
```

5. execute:
```shell
cd sepolia/2024-12-06-increase-max-gas-limit
make execute
```