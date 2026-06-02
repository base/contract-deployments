This is a repo of onchain operational tasks. Each network has its own directory with each individual task as a sub-directory.

Task writing:

- Use exact solidity pragma versions based on the contracts used by the task
  - Good: `pragma solidity 0.8.15`
  - Bad: `pragma solidity ^0.8.20`
- Always use "onchain" instead of "on-chain"
- Config values loaded from a `.env` should be loaded in a dedicated `setUp()` function in Solidity scripts/tests; avoid constructor-based setup unless immutables are specifically needed
- We only need task origin validation for mainnet scripts that go through proxy admin owner
- `RECORD_STATE_DIFF=true` is needed in the task `.env` file in order for the signer tool to work
- Include a `FACILITATOR.md` file directed to the task facilitator (explains generating validation file, executing approvals + executing the task)
- Always name the validation file(s) something simple like `base-signer.json` or `security-council-signer.json`. This results in human readable names in the signer tool
  - Do not attempt generating the validation file yourself - the engineer finalizing the task can do this
- The starting README status should be `READY TO SIGN`
- The README file is aimed at signers and should be as simple and concise as possible. Just enough information for signers to sign the task
