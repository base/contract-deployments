// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {ERC1967Factory} from "@solady/utils/ERC1967Factory.sol";
import {UpgradeableBeacon} from "@solady/utils/UpgradeableBeacon.sol";
import {ERC1967FactoryConstants} from "@solady/utils/ERC1967FactoryConstants.sol";

import {Twin} from "bridge/Twin.sol";
import {CrossChainERC20} from "bridge/CrossChainERC20.sol";
import {CrossChainERC20Factory} from "bridge/CrossChainERC20Factory.sol";
import {BridgeValidator} from "bridge/BridgeValidator.sol";
import {Bridge} from "bridge/Bridge.sol";
import {RelayerOrchestrator} from "bridge/periphery/RelayerOrchestrator.sol";

import {DevOps} from "./DevOps.s.sol";

struct Cfg {
    bytes32 salt;
    address erc1967Factory;
    address initialOwner;
}

contract DeployBridge is DevOps {
    Cfg public cfg = Cfg({
        salt: vm.envBytes32("CFG_SALT"),
        erc1967Factory: ERC1967FactoryConstants.ADDRESS,
        initialOwner: vm.envAddress("CFG_INITIAL_OWNER")
    });

    function run() public {
        address precomputedBridgeAddress = ERC1967Factory(cfg.erc1967Factory).predictDeterministicAddress(cfg.salt);

        vm.startBroadcast();
        address twinBeacon = _deployTwinBeacon({precomputedBridgeAddress: precomputedBridgeAddress});
        address factory = _deployFactory({precomputedBridgeAddress: precomputedBridgeAddress});
        address bridgeValidator = _deployBridgeValidator({bridge: precomputedBridgeAddress});
        address bridge =
            _deployBridge({twinBeacon: twinBeacon, crossChainErc20Factory: factory, bridgeValidator: bridgeValidator});
        address relayerOrchestrator = _deployRelayerOrchestrator({bridge: bridge, bridgeValidator: bridgeValidator});
        vm.stopBroadcast();

        require(address(bridge) == precomputedBridgeAddress, "Bridge address mismatch");

        _serializeAddress({key: "Bridge", value: bridge});
        _serializeAddress({key: "BridgeValidator", value: bridgeValidator});
        _serializeAddress({key: "CrossChainERC20Factory", value: factory});
        _serializeAddress({key: "Twin", value: twinBeacon});
        _serializeAddress({key: "RelayerOrchestrator", value: relayerOrchestrator});
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
            salt: cfg.salt,
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
}
