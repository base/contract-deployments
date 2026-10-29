# Base mainnet Denim upgrade

Status: READY TO SIGN

One ProxyAdmin-owner transaction replaces AggregateVerifier, registers Denim for
2026-11-05 18:00:00 UTC with minimum node version v1.5.1, and sends thirteen L2
upgrade deposits. The Security Council signs once, with eight member signatures.
The Base multisig requires three member signatures.

| Target | Current version | New version | New implementation | Basescan verified source |
| --- | --- | --- | --- | --- |
| AggregateVerifier, game type 621 | 0.2.0 | 0.3.0 | [`0xc08b8fFAF04Abb1d7013B74a0E57Eccbd7fa5A70`](https://etherscan.io/address/0xc08b8fFAF04Abb1d7013B74a0E57Eccbd7fa5A70#code) | N/A (L1) |
| L2ToL1MessagePasser | 1.0.0 | 1.2.0 | `0xF729d45aA58A015835A745474D4bd18551C3A92c` | [Basescan](https://basescan.org/address/0xF729d45aA58A015835A745474D4bd18551C3A92c#code) |
| L1Block | 1.7.0 | 1.8.0 | `0x8BDE8F549F56D405f07e1aA15Df9e1FC69839881` | [Basescan](https://basescan.org/address/0x8BDE8F549F56D405f07e1aA15Df9e1FC69839881#code) |
| SequencerFeeVault | 1.3.0 | 1.6.0 | `0x31574645D1Cc22778e10b394BF3713beA4aa2B68` | [Basescan](https://basescan.org/address/0x31574645D1Cc22778e10b394BF3713beA4aa2B68#code) |
| BaseFeeVault | 1.3.0 | 1.6.0 | `0x113B0749737B06D94267fe59e935D38e13849deF` | [Basescan](https://basescan.org/address/0x113B0749737B06D94267fe59e935D38e13849deF#code) |
| L1FeeVault | 1.3.0 | 1.6.0 | `0x93759deE9D2100Ca0a0e3EA10A0e5Cc5f07b229B` | [Basescan](https://basescan.org/address/0x93759deE9D2100Ca0a0e3EA10A0e5Cc5f07b229B#code) |
| OptimismMintableERC721Factory | 1.2.0 | 1.4.2 | `0x6e4f4f3E193880339c79605F88a2CD15370C8e02` | [Basescan](https://basescan.org/address/0x6e4f4f3E193880339c79605F88a2CD15370C8e02#code) |
| OperatorFeeVault | 1.0.0 | 1.1.0 | `0x47B6C3e3C3d8144c83910D26E3b517DF4f6058c7` | [Basescan](https://basescan.org/address/0x47B6C3e3C3d8144c83910D26E3b517DF4f6058c7#code) |
| SchemaRegistry | 1.0.1 | 1.3.1-beta.2 | `0xA88AB4351cC11acd42Ca148cd98Cfd91294Aa7BD` | [Basescan](https://basescan.org/address/0xA88AB4351cC11acd42Ca148cd98Cfd91294Aa7BD#code) |
| EAS | 1.0.1 | 1.4.1-beta.3 | `0xb6288DE3f61E3aCfAf4f1b0923656e2ab78C1Ad4` | [Basescan](https://basescan.org/address/0xb6288DE3f61E3aCfAf4f1b0923656e2ab78C1Ad4#code) |
| L2CrossDomainMessenger | 1.4.0 | 2.2.0 | `0xFe016829CbD44B469a4Bb76Ed95343A9458DCbA6` | [Basescan](https://basescan.org/address/0xFe016829CbD44B469a4Bb76Ed95343A9458DCbA6#code) |
| L2StandardBridge | 1.1.0 | 1.13.0 | `0xff312C3496f0848CD94d71dC06C434D487A46a10` | [Basescan](https://basescan.org/address/0xff312C3496f0848CD94d71dC06C434D487A46a10#code) |
| OptimismMintableERC20Factory | 1.9.0 | 1.10.2 | `0x87481a9CBf0aABf9a5f92838F51D9Ca635a33878` | [Basescan](https://basescan.org/address/0x87481a9CBf0aABf9a5f92838F51D9Ca635a33878#code) |
| L2ERC721Bridge | 1.1.0 | 1.10.0 | `0x6cf5489360C17e648d9009c74019699aa716d60c` | [Basescan](https://basescan.org/address/0x6cf5489360C17e648d9009c74019699aa716d60c#code) |

LegacyMigrator: `0x690D24732FB1Ed4869dCA5Cd2820FE54272aad09`. Basescan verified source: [Basescan](https://basescan.org/address/0x690D24732FB1Ed4869dCA5Cd2820FE54272aad09#code).
ProtocolVersions adds upgrade id 13.
BaseTime is excluded. Existing vault recipients and withdrawal networks are preserved.
EAS delegated signatures must be signed again for domain version 1.3.0.

The reproducible v1.5.2 prover hashes and their provenance are set in `.env`.
Before signing, the facilitator must verify all thirteen L2 implementations and LegacyMigrator on Basescan,
fill in their verified-source links above, and generate mainnet task-origin validations.

From the repository root:

```bash
make TASK_NETWORK=mainnet sign-task
```

Select `2026-10-07-denim-upgrade` for mainnet, sign, and send the signature to the facilitator.
