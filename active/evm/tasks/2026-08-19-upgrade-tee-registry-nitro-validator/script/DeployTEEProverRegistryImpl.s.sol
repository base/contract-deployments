// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {INitroValidator} from "interfaces/L1/proofs/tee/INitroValidator.sol";

import {TEEProverRegistry} from "@base-contracts/src/L1/proofs/tee/TEEProverRegistry.sol";

/// @notice Deploys a TEEProverRegistry implementation pointing at a hinted Nitro validator.
contract DeployTEEProverRegistryImpl is Script {
    address internal immutable disputeGameFactoryProxy;
    address internal immutable nitroValidator;
    string internal addressesJson;

    TEEProverRegistry public teeProverRegistryImpl;

    constructor() {
        disputeGameFactoryProxy = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        addressesJson = vm.envString("ADDRESSES_JSON");
        nitroValidator = vm.parseJsonAddress(vm.readFile(addressesJson), ".nitroValidator");
    }

    function setUp() public view {
        require(disputeGameFactoryProxy.code.length != 0, "dispute game factory not deployed");
        require(nitroValidator.code.length != 0, "nitro validator not deployed");
    }

    function run() external {
        vm.startBroadcast();

        teeProverRegistryImpl = new TEEProverRegistry({
            nitroValidator: INitroValidator(nitroValidator), factory: IDisputeGameFactory(disputeGameFactoryProxy)
        });

        vm.stopBroadcast();

        _postCheck();
        _writeAddress();
    }

    function _postCheck() internal view {
        require(address(teeProverRegistryImpl).code.length != 0, "tee registry implementation not deployed");
        require(address(teeProverRegistryImpl.NITRO_VALIDATOR()) == nitroValidator, "tee registry nitro mismatch");
        require(
            address(teeProverRegistryImpl.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxy,
            "tee registry factory mismatch"
        );
        require(keccak256(bytes(teeProverRegistryImpl.version())) == keccak256(bytes("0.6.1")), "version mismatch");
    }

    function _writeAddress() internal {
        console.log("TEEProverRegistryImpl:", address(teeProverRegistryImpl));
        vm.writeJson(vm.toString(address(teeProverRegistryImpl)), addressesJson, ".teeProverRegistryImpl");
    }
}
