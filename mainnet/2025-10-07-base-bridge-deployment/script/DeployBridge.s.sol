// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {ERC1967Factory} from "@solady/utils/ERC1967Factory.sol";
import {ERC1967FactoryConstants} from "@solady/utils/ERC1967FactoryConstants.sol";
import {LibString} from "solady/utils/LibString.sol";
import {UpgradeableBeacon} from "@solady/utils/UpgradeableBeacon.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

import {Pubkey} from "bridge/libraries/SVMLib.sol";
import {RelayerOrchestrator} from "bridge/periphery/RelayerOrchestrator.sol";
import {Bridge} from "bridge/Bridge.sol";
import {BridgeValidator} from "bridge/BridgeValidator.sol";
import {CrossChainERC20} from "bridge/CrossChainERC20.sol";
import {CrossChainERC20Factory} from "bridge/CrossChainERC20Factory.sol";
import {Twin} from "bridge/Twin.sol";

struct Cfg {
    bytes32 salt;
    address erc1967Factory;
    address initialOwner;
    address partnerValidators;
    address[] baseValidators;
    uint128 baseSignatureThreshold;
    uint256 partnerValidatorThreshold;
    Pubkey remoteBridge;
    address[] guardians;
}

contract DeployBridge is Script {
    using stdJson for string;
    using AddressAliasHelper for address;

    string public cfgData;
    Cfg public cfg;

    function setUp() public {
        cfgData = vm.readFile(string.concat(vm.projectRoot(), "/config.json"));

        cfg.salt = _readBytes32FromConfig("salt");
        cfg.erc1967Factory = ERC1967FactoryConstants.ADDRESS;
        cfg.initialOwner = _readAddressFromConfig("initialOwner").applyL1ToL2Alias();
        cfg.partnerValidators = _readAddressFromConfig("partnerValidators");
        cfg.baseValidators = _readAddressArrayFromConfig("baseValidators");
        cfg.baseSignatureThreshold = uint128(_readUintFromConfig("baseSignatureThreshold"));
        cfg.partnerValidatorThreshold = _readUintFromConfig("partnerValidatorThreshold");
        cfg.remoteBridge = Pubkey.wrap(_readBytes32FromConfig("remoteBridge"));
        cfg.guardians = _readAddressArrayFromConfig("guardians");

        require(cfg.guardians.length == 1, "invalid guardians length");
        cfg.guardians[0] = cfg.guardians[0].applyL1ToL2Alias();
    }

    function run() public {
        address precomputedBridgeAddress = ERC1967Factory(cfg.erc1967Factory).predictDeterministicAddress(_salt());

        vm.startBroadcast();
        address twinBeacon = _deployTwinBeacon({precomputedBridgeAddress: precomputedBridgeAddress});
        address factory = _deployFactory({precomputedBridgeAddress: precomputedBridgeAddress});
        address bridgeValidator = _deployBridgeValidator({bridge: precomputedBridgeAddress});
        address bridge =
            _deployBridge({twinBeacon: twinBeacon, crossChainErc20Factory: factory, bridgeValidator: bridgeValidator});
        address relayerOrchestrator = _deployRelayerOrchestrator({bridge: bridge, bridgeValidator: bridgeValidator});
        address sol = CrossChainERC20Factory(factory).deploySolWrapper();
        vm.stopBroadcast();

        require(address(bridge) == precomputedBridgeAddress, "Bridge address mismatch");

        _serializeAddress({key: "Bridge", value: bridge});
        _serializeAddress({key: "BridgeValidator", value: bridgeValidator});
        _serializeAddress({key: "CrossChainERC20Factory", value: factory});
        _serializeAddress({key: "Twin", value: twinBeacon});
        _serializeAddress({key: "RelayerOrchestrator", value: relayerOrchestrator});
        _serializeAddress({key: "WrappedSol", value: sol});

        _postCheck(twinBeacon, factory, bridgeValidator, bridge, relayerOrchestrator, sol);
    }

    function _postCheck(
        address twinBeacon,
        address factory,
        address bridgeValidator,
        address bridge,
        address relayerOrchestrator,
        address sol
    ) private view {
        // Twin
        Twin twinImpl = Twin(payable(UpgradeableBeacon(twinBeacon).implementation()));
        require(twinImpl.BRIDGE() == bridge, "PC01: incorrect bridge address in twin impl");

        // Factory
        UpgradeableBeacon tokenBeacon = UpgradeableBeacon(CrossChainERC20Factory(factory).BEACON());
        CrossChainERC20 tokenImpl = CrossChainERC20(tokenBeacon.implementation());
        require(tokenImpl.bridge() == bridge, "PC02: incorrect bridge address in token impl");

        // BridgeValidator
        require(
            BridgeValidator(bridgeValidator).BRIDGE() == bridge, "PC03: incorrect bridge address in BridgeValidator"
        );
        require(
            BridgeValidator(bridgeValidator).PARTNER_VALIDATORS() == cfg.partnerValidators,
            "PC04: incorrect partnerValidators address in BridgeValidator"
        );
        require(
            BridgeValidator(bridgeValidator).partnerValidatorThreshold() == cfg.partnerValidatorThreshold,
            "PC05: incorrect partner validator threshold in BridgeValidator"
        );
        require(
            BridgeValidator(bridgeValidator).getBaseThreshold() == cfg.baseSignatureThreshold,
            "PC06: incorrect Base threshold in BridgeValidator"
        );
        require(
            BridgeValidator(bridgeValidator).getBaseValidatorCount() == cfg.baseValidators.length,
            "PC07: incorrect registered base validator count"
        );

        for (uint256 i; i < cfg.baseValidators.length; i++) {
            require(
                BridgeValidator(bridgeValidator).isBaseValidator(cfg.baseValidators[i]),
                "PC08: base validator not registered"
            );
        }

        // Bridge
        require(Bridge(bridge).REMOTE_BRIDGE() == cfg.remoteBridge, "PC09: incorrect remote bridge in Bridge contract");
        require(Bridge(bridge).TWIN_BEACON() == twinBeacon, "PC10: incorrect twin beacon in Bridge contract");
        require(Bridge(bridge).CROSS_CHAIN_ERC20_FACTORY() == factory, "PC11: incorrect factory in Bridge contract");
        require(
            Bridge(bridge).BRIDGE_VALIDATOR() == bridgeValidator, "PC12: incorrect bridge validator in Bridge contract"
        );
        require(Bridge(bridge).owner() == cfg.initialOwner, "PC13: incorrect Bridge owner");

        for (uint256 i; i < cfg.guardians.length; i++) {
            require(
                Bridge(bridge).rolesOf(cfg.guardians[i]) == Bridge(bridge).GUARDIAN_ROLE(),
                "PC14: guardian missing perms"
            );
        }

        // RelayerOrchestrator
        require(
            RelayerOrchestrator(relayerOrchestrator).BRIDGE() == bridge, "PC15: incorrect bridge in RelayerOrchestrator"
        );
        require(
            RelayerOrchestrator(relayerOrchestrator).BRIDGE_VALIDATOR() == bridgeValidator,
            "PC16: incorrect bridge validator in RelayerOrchestrator"
        );

        // SOL
        require(CrossChainERC20(sol).bridge() == bridge, "PC17: incorrect bridge in SOL contract");
        require(LibString.eq(CrossChainERC20(sol).name(), "Solana"), "PC18: incorrect SOL name");
        require(LibString.eq(CrossChainERC20(sol).symbol(), "SOL"), "PC19: incorrect SOL symbol");
        require(
            CrossChainERC20(sol).remoteToken() == CrossChainERC20Factory(factory).SOL_PUBKEY(),
            "PC20: incorrect SOL remote token"
        );
        require(CrossChainERC20(sol).decimals() == 9, "PC21: incorrect SOL decimals");
    }

    function _deployTwinBeacon(address precomputedBridgeAddress) private returns (address) {
        address twinImpl = address(new Twin(precomputedBridgeAddress));
        return address(new UpgradeableBeacon({initialOwner: cfg.initialOwner, initialImplementation: twinImpl}));
    }

    function _deployFactory(address precomputedBridgeAddress) private returns (address) {
        address erc20Impl = address(new CrossChainERC20(precomputedBridgeAddress));
        address erc20Beacon =
            address(new UpgradeableBeacon({initialOwner: cfg.initialOwner, initialImplementation: erc20Impl}));

        address xChainErc20FactoryImpl = address(new CrossChainERC20Factory(erc20Beacon));
        return
            ERC1967Factory(cfg.erc1967Factory).deploy({implementation: xChainErc20FactoryImpl, admin: cfg.initialOwner});
    }

    function _deployBridgeValidator(address bridge) private returns (address) {
        address bridgeValidatorImpl =
            address(new BridgeValidator({bridgeAddress: bridge, partnerValidators: cfg.partnerValidators}));

        return ERC1967Factory(cfg.erc1967Factory).deployAndCall({
            implementation: bridgeValidatorImpl,
            admin: cfg.initialOwner,
            data: abi.encodeCall(
                BridgeValidator.initialize, (cfg.baseValidators, cfg.baseSignatureThreshold, cfg.partnerValidatorThreshold)
            )
        });
    }

    function _deployBridge(address twinBeacon, address crossChainErc20Factory, address bridgeValidator)
        private
        returns (address)
    {
        Bridge bridgeImpl = new Bridge({
            remoteBridge: cfg.remoteBridge,
            twinBeacon: twinBeacon,
            crossChainErc20Factory: crossChainErc20Factory,
            bridgeValidator: bridgeValidator
        });

        return ERC1967Factory(cfg.erc1967Factory).deployDeterministicAndCall({
            implementation: address(bridgeImpl),
            admin: cfg.initialOwner,
            salt: _salt(),
            data: abi.encodeCall(Bridge.initialize, (cfg.initialOwner, cfg.guardians))
        });
    }

    function _deployRelayerOrchestrator(address bridge, address bridgeValidator) private returns (address) {
        address relayerOrchestratorImpl =
            address(new RelayerOrchestrator({bridge: bridge, bridgeValidator: bridgeValidator}));

        return ERC1967Factory(cfg.erc1967Factory).deploy({
            implementation: relayerOrchestratorImpl,
            admin: cfg.initialOwner
        });
    }

    function _serializeAddress(string memory key, address value) private {
        vm.writeJson({
            json: LibString.toHexStringChecksummed(value),
            path: "addresses.json",
            valueKey: string.concat(".", key)
        });
    }

    function _readAddressFromConfig(string memory key) private view returns (address) {
        return vm.parseJsonAddress({json: cfgData, key: string.concat(".", key)});
    }

    function _readAddressArrayFromConfig(string memory key) private view returns (address[] memory) {
        return vm.parseJsonAddressArray({json: cfgData, key: string.concat(".", key)});
    }

    function _readUintFromConfig(string memory key) private view returns (uint256) {
        return vm.parseJsonUint({json: cfgData, key: string.concat(".", key)});
    }

    function _readBytes32FromConfig(string memory key) private view returns (bytes32) {
        return vm.parseJsonBytes32({json: cfgData, key: string.concat(".", key)});
    }

    function _salt() private view returns (bytes32) {
        bytes12 s = bytes12(keccak256(abi.encode(cfg.salt)));
        return bytes32(abi.encodePacked(msg.sender, s));
    }
}
