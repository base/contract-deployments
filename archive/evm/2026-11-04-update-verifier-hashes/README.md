# Rotate verifier hashes

Pre-reviewed standby operation for AggregateVerifier 0.3.0. No network invocation is configured here.

Follow [FACILITATOR.md](FACILITATOR.md) to deploy and source-verify a replacement, validate immutable continuity, collect Base and Security Council approvals, execute the factory switch, and archive. Create an invocation with `make new-task STANDBY_OP=update-verifier-hashes TASK_NETWORK=<network>` from the repository root; it adds only `config/<network>/.env`, a signer README, and task-root `status.json`. Generated artifacts remain network-scoped, with Forge records at task scope.
