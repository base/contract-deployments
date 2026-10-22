# Base mainnet Denim upgrade

Status: READY TO SIGN

One ProxyAdmin-owner transaction replaces AggregateVerifier, registers Denim for
2026-11-05 18:00:00 UTC with minimum node version v1.5.1, and sends thirteen L2
upgrade deposits. The Security Council signs once, with eight member signatures.
The Base multisig requires three member signatures.

| Target | Current version | New version | New implementation |
| --- | --- | --- | --- |
| AggregateVerifier, game type 621 | 0.2.0 | 0.3.0 | Pending deployment |
| L2ToL1MessagePasser | 1.0.0 | 1.2.0 | Pending deployment |
| L1Block | 1.7.0 | 1.8.0 | Pending deployment |
| SequencerFeeVault | 1.3.0 | 1.6.0 | Pending deployment |
| BaseFeeVault | 1.3.0 | 1.6.0 | Pending deployment |
| L1FeeVault | 1.3.0 | 1.6.0 | Pending deployment |
| OptimismMintableERC721Factory | 1.2.0 | 1.4.2 | Pending deployment |
| OperatorFeeVault | 1.0.0 | 1.1.0 | Pending deployment |
| SchemaRegistry | 1.0.1 | 1.3.1-beta.2 | Pending deployment |
| EAS | 1.0.1 | 1.4.1-beta.3 | Pending deployment |
| L2CrossDomainMessenger | 1.4.0 | 2.2.0 | Pending deployment |
| L2StandardBridge | 1.1.0 | 1.13.0 | Pending deployment |
| OptimismMintableERC20Factory | 1.9.0 | 1.10.2 | Pending deployment |
| L2ERC721Bridge | 1.1.0 | 1.10.0 | Pending deployment |

LegacyMigrator: Pending deployment. ProtocolVersions adds upgrade id 13.
BaseTime is excluded. Existing vault recipients and withdrawal networks are preserved.
EAS delegated signatures must be signed again for domain version 1.3.0.

The reproducible v1.5.1-based prover hashes and their provenance are set in `.env`.
The facilitator must deploy the implementations and generate mainnet task-origin validations before signing.

From the repository root:

```bash
make TASK_NETWORK=mainnet sign-task
```

Select `2026-10-07-denim-upgrade` for mainnet, sign, and send the signature to the facilitator.
