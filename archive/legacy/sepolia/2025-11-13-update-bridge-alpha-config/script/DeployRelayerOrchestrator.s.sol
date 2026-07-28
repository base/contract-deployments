// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ERC1967Factory} from "@solady/utils/ERC1967Factory.sol";
import {ERC1967FactoryConstants} from "@solady/utils/ERC1967FactoryConstants.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

import {RelayerOrchestrator} from "bridge/periphery/RelayerOrchestrator.sol";

struct Cfg {
    address erc1967Factory;
    address initialOwner;
    address partnerValidators;
    address[] baseValidators;
    uint256 partnerValidatorThreshold;
}

contract DeployRelayerOrchestrator is Script {
    using stdJson for string;
    using AddressAliasHelper for address;

    string public cfgData;
    Cfg public cfg;

    function setUp() public {
        cfgData = vm.readFile(string.concat(vm.projectRoot(), "/config.json"));

        cfg.erc1967Factory = ERC1967FactoryConstants.ADDRESS;
        cfg.initialOwner = _readAddressFromConfig("initialOwner").applyL1ToL2Alias();
    }

    function run() public {
        address bridgeProxy = 0x64567a9147fa89B1edc987e36Eb6f4b6db71656b;
        address bridgeValidatorProxy = 0xC05324843aca6C2b7446F15bdB17AF4599b761E6;

        vm.startBroadcast();
        address relayerOrchestratorProxy =
            _deployRelayerOrchestrator({bridge: bridgeProxy, bridgeValidator: bridgeValidatorProxy});
        vm.stopBroadcast();

        _serializeAddress({key: "RelayerOrchestratorProxy", value: relayerOrchestratorProxy});
    }

    function _deployRelayerOrchestrator(address bridge, address bridgeValidator) private returns (address) {
        address relayerOrchestratorImpl =
            address(new RelayerOrchestrator({bridge: bridge, bridgeValidator: bridgeValidator}));

        return
            ERC1967Factory(cfg.erc1967Factory)
                .deploy({implementation: relayerOrchestratorImpl, admin: cfg.initialOwner});
    }

    function _serializeAddress(string memory key, address value) private {
        vm.writeJson({
            json: LibString.toHexStringChecksummed(value), path: "newAddresses.json", valueKey: string.concat(".", key)
        });
    }

    function _readAddressFromConfig(string memory key) private view returns (address) {
        return vm.parseJsonAddress({json: cfgData, key: string.concat(".", key)});
    }
}
