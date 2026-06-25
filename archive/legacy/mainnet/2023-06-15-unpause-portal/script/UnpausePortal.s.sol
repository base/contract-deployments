// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@base-contracts/script/calls/UnpausePortal.s.sol";

contract RunUnpausePortal is Script {
    function run(address _safe) public {
        UnpausePortal unpausePortal = new UnpausePortal();
        unpausePortal.run(_safe);
    }
}