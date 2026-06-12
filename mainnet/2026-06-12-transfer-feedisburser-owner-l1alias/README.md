# Transfer Mainnet `FeeDisburser` Owner

Status: READY TO SIGN

## Description

This task transfers the Base mainnet [`FeeDisburser`](https://basescan.org/address/0x09C7bAD99688a55a2e83644BFAed09e62bDcCcBA) proxy owner from the aliased old Coinbase L1 multisig to the aliased new Coinbase L1 multisig.

| Role | L1 address | L2 alias |
| -- | -- | -- |
| Current owner | `0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110` | `0xaD5B57FEB77e294fD7BF5EBE9aB01caA0a90B221` |
| New owner | `0x9855054731540A48b28990B63DcF4f33d8AE46A1` | `0xa966054731540a48b28990b63Dcf4f33d8aE57B2` |

The call is executed from Ethereum mainnet through `OptimismPortal2`, which causes the old L1 multisig's aliased address to call `changeAdmin` on the Base mainnet `FeeDisburser` proxy.

## Approving the transaction

### 1. Update repo

```bash
cd contract-deployments
git pull
```

### 2. Run the signing tool

Run this command from the repo root. Do not enter the task directory.

```bash
make sign-task
```

### 3. Sign

Open [http://localhost:3000](http://localhost:3000) and select:

```text
mainnet/2026-06-12-transfer-feedisburser-owner-l1alias
```

After signing, copy the signature and send it to the facilitator. You may then close the signer tool with `Ctrl + C`.
