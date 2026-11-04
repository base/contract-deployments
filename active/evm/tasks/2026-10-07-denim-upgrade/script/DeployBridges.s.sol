// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {ISemver} from "interfaces/universal/ISemver.sol";
import {L2CrossDomainMessenger} from "@base-contracts/src/L2/L2CrossDomainMessenger.sol";
import {L2StandardBridge} from "@base-contracts/src/L2/L2StandardBridge.sol";
import {L2ERC721Bridge} from "@base-contracts/src/L2/L2ERC721Bridge.sol";
import {LegacyMigrator} from "./LegacyMigrator.sol";

contract DeployBridges is Script {
    function run() external {
        vm.startBroadcast();
        address[3] memory implementations =
            [address(new L2CrossDomainMessenger()), address(new L2StandardBridge()), address(new L2ERC721Bridge())];
        LegacyMigrator migrator = new LegacyMigrator();
        vm.stopBroadcast();
        string[3] memory versions = [string("2.2.0"), "1.13.0", "1.10.0"];
        string[3] memory keys = [string(".l2CrossDomainMessenger"), ".l2StandardBridge", ".l2ERC721Bridge"];
        string memory path = vm.envString("ADDRESSES_JSON");
        for (uint256 i; i < 3; i++) {
            require(
                keccak256(bytes(ISemver(implementations[i]).version())) == keccak256(bytes(versions[i])),
                "bridge version mismatch"
            );
            vm.writeJson(vm.toString(implementations[i]), path, keys[i]);
        }
        vm.writeJson(vm.toString(address(migrator)), path, ".legacyMigrator");
    }
}
