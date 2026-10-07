# Transfer Sepolia `BalanceTracker` Ownership

Status: READY TO SIGN

## Description

Move the admin of the Ethereum Sepolia
[`BalanceTracker`](https://sepolia.etherscan.io/address/0x8D1b5e5614300F5c7ADA01fFA4ccF8F1752D9A57)
proxy from the EOA `0x4672425C27A942bB27e7b9709c1b21ab89a3cA13` to the Base Sepolia multisig
[`0x646132A1667ca7aD00d36616AFBA1A28116C770A`](https://sepolia.etherscan.io/address/0x646132A1667ca7aD00d36616AFBA1A28116C770A).

## Execution

The proxy is administered by an EOA, so no multisig signature is required. The facilitator
executes the transfer with the current admin's Ledger.
