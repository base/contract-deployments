To sign, multisig signers will need to:
1. Clone the contract-deployments repo and checkout the disburse-basenames branch
2. cd into the 2024-08-27-disburse-basenames directory
3. run `make deps`
4. run `make sign {NUMBER}` where `NUMBER` corresponds to both the `nonce` and the disbursement csv file. 
5. With your ledger connected, it will prompt you to sign the message hash
6. With your ledger disconnected, this will generate a tenderly sim
7. Copy the tenderly sim link into your browser. Grab the calldata blob and paste it into the `Enter raw input data` field on the left. Verify that the state transitions are valid. Specifically check that the NFT tokens are being sent to the addresses specified in the csv. 
