# Mainnet Beryl Upgrade

Status: READY TO SIGN

## Transactions

- New `AggregateVerifier` deployment ([`0x1bd8db5139Ba7aC9277684650c15e6E341761919`](https://etherscan.io/address/0x1bd8db5139Ba7aC9277684650c15e6E341761919)): [`0xda9240db370b784bb621aca01937db27256fe9aad73df6555356c6cd36c286b6`](https://etherscan.io/tx/0xda9240db370b784bb621aca01937db27256fe9aad73df6555356c6cd36c286b6) (artefacts: [run-1781824443277.json](./records/DeployAggregateVerifier.s.sol/1/run-1781824443277.json))
- Security Council approval ([`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`](https://etherscan.io/address/0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd)): [`0x7f35d9a9fbc5e886f9c92fbd155c872f174299d23002c684ddac626d2de55ae0`](https://etherscan.io/tx/0x7f35d9a9fbc5e886f9c92fbd155c872f174299d23002c684ddac626d2de55ae0) (artefacts: [run-1782136357812.json](./records/UpdateVerifierHashes.s.sol/1/run-1782136357812.json))

## Description

This task updates the TEE and ZK verifier hashes of the multiproof implementation on Base mainnet.

- redeploying `AggregateVerifier` with identical immutables, overriding `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
- pointing `DisputeGameFactory.gameImpls(gameType)` at the new `AggregateVerifier`

The final Mainnet Beryl hash values are configured in `.env`.

## Procedure

### Sign task

#### 1. Update repo

```bash
cd contract-deployments
git pull
```

#### 2. Run signing tool

```bash
make sign-task
```

#### 3. Open the UI at [http://localhost:3000](http://localhost:3000)

- Select the correct signer role from the list of available users to sign.
- After completion, close the signer tool with `Ctrl + C`.

#### 4. Send signature to facilitator

Copy the signature output and send it to the designated facilitator via the agreed communication channel.

For facilitator instructions, see `FACILITATOR.md`.
