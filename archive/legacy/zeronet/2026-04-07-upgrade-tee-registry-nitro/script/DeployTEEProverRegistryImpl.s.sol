// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {INitroEnclaveVerifier} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";

contract DeployTeeProverRegistryImpl is Script {
    address internal disputeGameFactoryProxyEnv;
    address internal nitroEnclaveVerifier;

    address public teeProverRegistryImpl;

    function setUp() public {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
    }

    function run() external {
        vm.startBroadcast();

        teeProverRegistryImpl = address(
            new TEEProverRegistry({
                nitroVerifier: INitroEnclaveVerifier(nitroEnclaveVerifier),
                factory: IDisputeGameFactory(disputeGameFactoryProxyEnv)
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        TEEProverRegistry registry = TEEProverRegistry(teeProverRegistryImpl);
        require(address(registry.NITRO_VERIFIER()) == nitroEnclaveVerifier, "tee registry nitro mismatch");
        require(address(registry.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "tee registry dgf mismatch");
    }

    function _writeAddresses() internal {
        console.log("TEEProverRegistryImpl:", teeProverRegistryImpl);
        vm.writeJson({
            json: vm.toString(teeProverRegistryImpl), path: "addresses.json", valueKey: ".teeProverRegistryImpl"
        });
    }
}
