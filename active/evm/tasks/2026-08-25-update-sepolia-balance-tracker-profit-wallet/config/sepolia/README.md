# Update Sepolia `BalanceTracker` Profit Wallet

Status: READY TO SIGN

## Description

Replace the Base Sepolia `BalanceTracker` profit wallet
`0x5A822ea15764a6090b86B1EABfFc051cEC99AFE9` with the company-owned wallet
used on mainnet, `0xEc8103eb573150cB92f8AF612e0072843db2295F`.

The existing system addresses and target balances remain unchanged.

## Execution

The `BalanceTracker` proxy is administered by an EOA, so no multisig signature
is required. The facilitator executes the upgrade with the existing proxy admin
Ledger.
