# Facilitator Guide

Guide for facilitators managing this task.

## Update repo:

```bash
cd contract-deployments
git pull
cd sepolia/2026-03-11-patch-fee-disburser
make deps
```

## Task Origin Signing

After setting up the task, generate cryptographic attestations (sigstore bundles) to prove who created and facilitated the task. These signatures are stored in `<network>/signatures/<task-name>/`.

### Task creator (run after task setup):

```bash
make sign-as-task-creator
```

### Base facilitator:

```bash
make sign-as-base-facilitator
```

### Security Council facilitator:

```bash
make sign-as-sc-facilitator
```
