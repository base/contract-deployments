# Deploy new PermissionedDisputeGame

Status: ready to execute

## Objective

We are deploying a new `PermissionedDisputeGame` so that it has the new proposer address

This runbook implements scripts which allow system owner to execute:
1. `DeployNewPDG` -- Deploys a new `PermissionedDisputeGame` with the new proposer address.

The values we are sending are statically defined in the `.env`.

## Deploy the new PDG
This step doesn't have to be done with multisig, we can use an EoA to deploy by running `make execute-deploy-dispute-game`. We should see the following output from the console
```
== Logs ==
  New permissioned dispute game address:  <SOME ADDRESS>
  New proposer:  0x037637067c1DbE6d2430616d8f54Cb774Daa5999
```
