# Everest upgrade facilitator guide

One ProxyAdmin-owner transaction makes two calls:

| Change | Contract and call |
| --- | --- |
| Everest proof program hashes | `DisputeGameFactory.setImplementation(621, newAggregateVerifier)` |
| Everest activation and minimum node version | `ProtocolVersions.registerUpgrade(EVEREST_ACTIVATION_TIMESTAMP, PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION)`, upgrade id 14 |

The new `AggregateVerifier` stays at `0.3.0`; only its three proof program hashes change. Games bind
`ProtocolVersions.activatedScheduleId(claimTimestamp)`, so the registered Everest activation must match the
activation compiled into the prover build that produced the hashes.

Run commands from this task directory, replacing `<network>` with the rollout network. Every command needs
`TASK_NETWORK=<network>` on the command line.

## 1. Fill in and review the network config

Open `config/<network>/.env` and confirm:

- `CURRENT_AGGREGATE_VERIFIER` is `DisputeGameFactory.gameImpls(621)` and reports version `0.3.0`.
- `AGGREGATE_VERIFIER_TEE_IMAGE_HASH`, `AGGREGATE_VERIFIER_ZK_RANGE_HASH` and
  `AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH` come from the reproducible base/base build the network's provers run
  at Everest. Record the source commit, build recipe, PCR0 and SP1 vkeys in the `.env` comments. The TEE hash is
  `cast keccak 0x<PCR0>`, not PCR0 itself. `just succinct vkeys --build` prints both ZK vkeys; do not swap
  the labels.
- `EVEREST_ACTIVATION_TIMESTAMP` matches the Everest activation in that base/base release.
- `PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION` is the live value and
  `PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION` is the packed version of the release that activates Everest.

Network addresses come from the repository's `config/<network>.env`. Every Make target that needs a blank
input refuses to run.

## 2. Deploy and verify the AggregateVerifier

```bash
make TASK_NETWORK=<network> deps
make TASK_NETWORK=<network> deploy
VERIFIER_API_KEY=<key> make TASK_NETWORK=<network> verify
```

`deploy` runs the pre-reviewed standby script
`standby/evm/tasks/update-verifier-hashes/script/DeployAggregateVerifier.s.sol` from the facilitator's Ledger. It
copies every non-hash constructor input from `CURRENT_AGGREGATE_VERIFIER`, checks every immutable of the new
verifier, and writes `aggregateVerifier` and its constructor arguments to `config/<network>/addresses.json`. It
builds with base/contracts' AggregateVerifier settings: 0.8.15, 999999 optimizer runs, no bytecode hash, Cancun.

Commit `config/<network>/addresses.json` and the task-scoped `records/`, then fill in the new verifier address
and the Everest date in `config/<network>/README.md`.

## 3. Generate validation files

```bash
make TASK_NETWORK=<network> gen-validation-cb
make TASK_NETWORK=<network> gen-validation-sc
make TASK_NETWORK=<network> check-validations
```

These write `config/<network>/validations/base-signer.json` and `security-council-signer.json`. Replace any
generated `<<ContractName>>` or `<<Summary>>` placeholders. Expected state changes:

- `DisputeGameFactory`: `gameImpls[621]` moves from `CURRENT_AGGREGATE_VERIFIER` to the new verifier. The script
  rejects any other factory storage write.
- `ProtocolVersions`: a 15th schedule entry (Everest) with `EVEREST_ACTIVATION_TIMESTAMP`, the extended schedule
  id chain, and the new minimum protocol version.
- Safe nonce and approval changes.

For non-mainnet networks, generation sets `skipTaskOriginValidation`. For mainnet, keep `taskOriginConfig` and
collect task-origin signatures after the task folder is final:

```bash
make TASK_NETWORK=mainnet sign-as-task-creator
make TASK_NETWORK=mainnet sign-as-base-facilitator
make TASK_NETWORK=mainnet sign-as-sc-facilitator
```

Commit the validations, set the network step in `status.json` to `ready_to_sign`, and share
`config/<network>/README.md` with signers.

## 4. Collect signatures and execute

The ProxyAdmin owner is a 2-of-2 of the Base multisig and the Security Council, so each approves its own nested
Safe before the outer transaction runs.

```bash
SIGNATURES=<concatenated base signatures>             make TASK_NETWORK=<network> approve-cb
SIGNATURES=<concatenated security council signatures> make TASK_NETWORK=<network> approve-sc
make TASK_NETWORK=<network> execute
```

Execute at least one hour before `EVEREST_ACTIVATION_TIMESTAMP`, preferably with margin; `ProtocolVersions`
enforces this `MIN_NOTICE`. Once registered, the activation can only be delayed by the incident responder (see
`standby/evm/tasks/delay-upgrade-activation`) and freezes one hour before it lands.

Immediately after execution, roll the network's proposer and provers to the prover build the hashes came from.
The new verifier accepts proofs only from that build, so proposals pause until the rollout lands. Confirm the new
enclave signers registered with the expected image hash:

```bash
cast call "$TEE_PROVER_REGISTRY_PROXY" 'getRegisteredSigners()(address[])' --rpc-url "$L1_RPC_URL"
cast call "$TEE_PROVER_REGISTRY_PROXY" 'signerImageHash(address)(bytes32)' <signer> --rpc-url "$L1_RPC_URL"
```

After execution the script checks that the factory points at the new verifier, that Everest is upgrade id 14 with
the expected timestamp, that earlier upgrades are unchanged, and that the minimum protocol version is updated.

Commit the final `records/`, set `config/<network>/README.md` to `Status: EXECUTED` with the transaction link,
and update the network in `status.json` in the same change. Run `make check-task-status` from the repository
root. Archive only after every intended network is executed or canceled.
