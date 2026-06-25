// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "@base-contracts/src/smart-escrow/SmartEscrow.sol";

contract DeploySmartEscrow is Script {
    address internal BENEFACTOR = vm.envAddress("BENEFACTOR");
    address internal BENEFICIARY = vm.envAddress("BENEFICIARY");
    address internal BENEFACTOR_OWNER = vm.envAddress("BENEFACTOR_OWNER");
    address internal BENEFICIARY_OWNER = vm.envAddress("BENEFICIARY_OWNER");
    address internal ESCROW_OWNER = vm.envAddress("NESTED_SAFE");
    uint256 internal START = vm.envUint("START");
    uint256 internal CLIFF_START = vm.envUint("CLIFF_START");
    uint256 internal END = vm.envUint("END");
    uint256 internal VESTING_PERIOD_SECONDS = vm.envUint("VESTING_PERIOD_SECONDS");
    uint256 internal INITIAL_TOKENS = vm.envUint("INITIAL_TOKENS");
    uint256 internal VESTING_EVENT_TOKENS = vm.envUint("VESTING_EVENT_TOKENS");

    function run() public {
        vm.broadcast();
        SmartEscrow smartEscrow = new SmartEscrow(
            BENEFACTOR,
            BENEFICIARY,
            BENEFACTOR_OWNER,
            BENEFICIARY_OWNER,
            ESCROW_OWNER,
            START,
            CLIFF_START,
            END,
            VESTING_PERIOD_SECONDS,
            INITIAL_TOKENS,
            VESTING_EVENT_TOKENS
        );
        require(smartEscrow.start() == START, "DeploySmartEscrow: start time not set correctly");
        require(smartEscrow.cliffStart() == CLIFF_START, "DeploySmartEscrow: cliff start time not set correctly");
        require(smartEscrow.end() == END, "DeploySmartEscrow: end time not set correctly");
        require(smartEscrow.vestingPeriod() == VESTING_PERIOD_SECONDS, "DeploySmartEscrow: vesting period incorrect");
        require(smartEscrow.initialTokens() == INITIAL_TOKENS, "DeploySmartEscrow: number of initial tokens incorrect");
        require(smartEscrow.vestingEventTokens() == VESTING_EVENT_TOKENS, "DeploySmartEscrow: number of vesting event tokens incorrect");
        require(smartEscrow.benefactor() == BENEFACTOR, "DeploySmartEscrow: benefactor incorrect"); 
        require(smartEscrow.beneficiary() == BENEFICIARY, "DeploySmartEscrow: beneficiary incorrect");
        require(smartEscrow.released() == 0, "DeploySmartEscrow: initial released value must be zero");
        require(smartEscrow.contractTerminated() == false, "DeploySmartEscrow: contract cannot initially be terminated");
    }
}
