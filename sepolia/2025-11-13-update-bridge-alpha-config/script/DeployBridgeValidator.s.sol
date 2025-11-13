// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ERC1967Factory} from "@solady/utils/ERC1967Factory.sol";
import {ERC1967FactoryConstants} from "@solady/utils/ERC1967FactoryConstants.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

import {Bridge} from "bridge/Bridge.sol";
import {BridgeValidator} from "bridge/BridgeValidator.sol";
import {Pubkey} from "bridge/libraries/SVMLib.sol";

struct Cfg {
    address erc1967Factory;
    address initialOwner;
    address partnerValidators;
    address[] baseValidators;
    uint256 partnerValidatorThreshold;
}

contract DeployBridgeUpdates is Script {
    using stdJson for string;
    using AddressAliasHelper for address;

    string public cfgData;
    Cfg public cfg;

    address public immutable BRIDGE_PROXY;
    address public immutable BRIDGE_VALIDATOR_PROXY;

    constructor() {
        BRIDGE_PROXY = vm.envAddress("L2_BRIDGE_PROXY");
        BRIDGE_VALIDATOR_PROXY = vm.envAddress("BRIDGE_VALIDATOR_PROXY");
    }

    function setUp() public {
        cfgData = vm.readFile(string.concat(vm.projectRoot(), "/config.json"));

        cfg.erc1967Factory = ERC1967FactoryConstants.ADDRESS;
        cfg.initialOwner = _readAddressFromConfig("initialOwner").applyL1ToL2Alias();
        cfg.partnerValidators = _readAddressFromConfig("partnerValidators");
        cfg.baseValidators = _readAddressArrayFromConfig("baseValidators");
        cfg.partnerValidatorThreshold = _readUintFromConfig("partnerValidatorThreshold");
    }

    function run() public {
        address twinBeacon = Bridge(BRIDGE_PROXY).TWIN_BEACON();
        address crossChainErc20Factory = Bridge(BRIDGE_PROXY).CROSS_CHAIN_ERC20_FACTORY();
        Pubkey remoteBridge = Bridge(BRIDGE_PROXY).REMOTE_BRIDGE();
        uint128 baseThreshold = BridgeValidator(BRIDGE_VALIDATOR_PROXY).getBaseThreshold();
        uint256 baseSignerCount = BridgeValidator(BRIDGE_VALIDATOR_PROXY).getBaseValidatorCount();

        require(baseSignerCount == cfg.baseValidators.length, "Precheck 00");

        for (uint256 i; i < baseSignerCount; i++) {
            require(BridgeValidator(BRIDGE_VALIDATOR_PROXY).isBaseValidator(cfg.baseValidators[i]), "Precheck 01");
        }

        vm.startBroadcast();
        address bridgeValidatorImpl =
            address(new BridgeValidator({bridgeAddress: BRIDGE_PROXY, partnerValidators: cfg.partnerValidators}));
        address bridgeValidatorProxy = ERC1967Factory(cfg.erc1967Factory)
            .deployAndCall({
                implementation: bridgeValidatorImpl,
                admin: cfg.initialOwner,
                data: abi.encodeCall(
                    BridgeValidator.initialize, (cfg.baseValidators, baseThreshold, cfg.partnerValidatorThreshold)
                )
            });

        address bridgeImpl = address(
            new Bridge({
                remoteBridge: remoteBridge,
                twinBeacon: twinBeacon,
                crossChainErc20Factory: crossChainErc20Factory,
                bridgeValidator: bridgeValidatorProxy
            })
        );
        vm.stopBroadcast();

        _serializeAddress({key: "BridgeValidatorProxy", value: bridgeValidatorProxy});
        _serializeAddress({key: "BridgeImpl", value: bridgeImpl});
    }

    function _serializeAddress(string memory key, address value) private {
        vm.writeJson({
            json: LibString.toHexStringChecksummed(value), path: "addresses.json", valueKey: string.concat(".", key)
        });
    }

    function _readUintFromConfig(string memory key) private view returns (uint256) {
        return vm.parseJsonUint({json: cfgData, key: string.concat(".", key)});
    }

    function _readAddressArrayFromConfig(string memory key) private view returns (address[] memory) {
        return vm.parseJsonAddressArray({json: cfgData, key: string.concat(".", key)});
    }

    function _readAddressFromConfig(string memory key) private view returns (address) {
        return vm.parseJsonAddress({json: cfgData, key: string.concat(".", key)});
    }
}
