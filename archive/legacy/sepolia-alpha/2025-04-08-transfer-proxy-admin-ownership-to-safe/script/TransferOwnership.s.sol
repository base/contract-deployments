// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract TransferOwnership is Script {
    address public immutable NEW_OWNER;
    address public immutable PROXY_ADMIN;

    constructor() {
        NEW_OWNER = vm.envAddress("NEW_OWNER");
        PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
    }

    function run() public {
        Simulation.StateOverride[] memory overrides;
        bytes memory data = _buildCall();
        Simulation.logSimulationLink({_to: PROXY_ADMIN, _data: data, _from: msg.sender, _overrides: overrides});

        vm.startBroadcast();
        (bool success, ) = PROXY_ADMIN.call(data);
        vm.stopBroadcast();

        require(success, "TransferOwnership call failed");
        _postCheck();
    }

    function _buildCall() private view returns (bytes memory) {
        return abi.encodeCall(OwnableUpgradeable.transferOwnership, (NEW_OWNER));
    }

    function _postCheck() private view {
        OwnableUpgradeable proxyAdmin = OwnableUpgradeable(PROXY_ADMIN);
        require(proxyAdmin.owner() == NEW_OWNER, "ProxyAdmin owner did not get updated");
    }
}
