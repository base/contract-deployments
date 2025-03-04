// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/L1/L2OutputOracle.sol";
import "forge-std/Script.sol";

contract SetupNewProposer is Script {
    address constant internal NEW_PROPOSER = vm.envUint("NEW_PROPOSER"); // TODO: define NEW_PROPOSER=xxx in the .env file
    address constant internal DEPLOYER = vm.envAddress("DEPLOYER"); // TODO: define DEPLOYER=xxx in the .env file
    address constant internal L2_OUTPUT_ORACLE_PROXY = vm.envAddress("L2_OUTPUT_ORACLE_PROXY"); // TODO: define L2_OUTPUT_ORACLE_PROXY=xxx in the .env file

    function run() public {
        L2OutputOracle existingL2OO = L2OutputOracle(L2_OUTPUT_ORACLE_PROXY);
        uint256 oldSubmissionInterval = existingL2OO.SUBMISSION_INTERVAL();
        uint256 oldL2BlockTime = existingL2OO.L2_BLOCK_TIME();
        uint256 oldFinalizationPeriodSeconds = existingL2OO.FINALIZATION_PERIOD_SECONDS();
        uint256 startingBlockNumber = existingL2OO.startingBlockNumber();
        uint256 startingTimestamp = existingL2OO.startingTimestamp();
        address oldProposer = existingL2OO.PROPOSER();
        address oldChallenger = existingL2OO.CHALLENGER();

        console.log(oldProposer);
        console.log(NEW_PROPOSER);

        // Deploy L2OutputOracle new implementation with the new submission interval
        vm.broadcast(DEPLOYER);
        L2OutputOracle l2OutputOracleImpl = new L2OutputOracle({
            _submissionInterval: oldSubmissionInterval,
            _l2BlockTime: oldL2BlockTime,
            _startingBlockNumber: startingBlockNumber,
            _startingTimestamp: startingTimestamp,
            _proposer: NEW_PROPOSER,
            _challenger: oldChallenger,
            _finalizationPeriodSeconds: oldFinalizationPeriodSeconds            
        });

        require(l2OutputOracleImpl.L2_BLOCK_TIME() == oldL2BlockTime, "Deploy: l2OutputOracle l2BlockTime is incorrect");
        require(l2OutputOracleImpl.PROPOSER() == NEW_PROPOSER, "Deploy: l2OutputOracle proposer is incorrect");

        console.logAddress(address(l2OutputOracleImpl));
    }
}
