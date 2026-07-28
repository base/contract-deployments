// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType, Hash, Proposal} from "@base-contracts/src/dispute/lib/Types.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
}

interface IProxy {
    function implementation() external view returns (address);
}

/// @notice Corrects the starting anchor root stored in the AnchorStateRegistry.
contract FixStartingAnchorRoot is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    address internal currentAnchorStateRegistryImpl;
    uint256 internal currentAsrDisputeGameFinalityDelaySeconds;
    uint8 internal currentAsrInitVersion;

    address internal nextAnchorStateRegistryImpl;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        require(IProxyAdmin(proxyAdminEnv).owner() == ownerSafeEnv, "proxy admin owner mismatch");

        AnchorStateRegistry currentAsr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        currentAsrDisputeGameFinalityDelaySeconds = currentAsr.disputeGameFinalityDelaySeconds();
        currentAsrInitVersion = currentAsr.initVersion();

        vm.prank(proxyAdminEnv);
        currentAnchorStateRegistryImpl = IProxy(anchorStateRegistryProxyEnv).implementation();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nextAnchorStateRegistryImpl = vm.parseJsonAddress({json: json, key: ".anchorStateRegistryImpl"});

        require(nextAnchorStateRegistryImpl != address(0), "next asr impl not set");
        require(nextAnchorStateRegistryImpl != currentAnchorStateRegistryImpl, "next asr impl equals current");
        require(startingAnchorRootEnv != bytes32(0), "starting anchor root not set");
        require(startingAnchorL2BlockNumberEnv != 0, "starting anchor block not set");

        AnchorStateRegistry nextAsrImpl = AnchorStateRegistry(nextAnchorStateRegistryImpl);
        require(
            nextAsrImpl.disputeGameFinalityDelaySeconds() == currentAsrDisputeGameFinalityDelaySeconds,
            "next asr finality delay mismatch"
        );
        require(nextAsrImpl.initVersion() == currentAsrInitVersion + 1, "next asr init version mismatch");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    anchorStateRegistryProxyEnv,
                    nextAnchorStateRegistryImpl,
                    abi.encodeCall(
                        AnchorStateRegistry.initialize,
                        (
                            ISystemConfig(systemConfigEnv),
                            IDisputeGameFactory(disputeGameFactoryProxyEnv),
                            Proposal({
                                root: Hash.wrap(startingAnchorRootEnv), l2SequenceNumber: startingAnchorL2BlockNumberEnv
                            }),
                            gameTypeEnv
                        )
                    )
                )
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        AnchorStateRegistry asr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        Proposal memory startingAnchor = asr.getStartingAnchorRoot();
        (Hash currentAnchorRoot, uint256 currentAnchorL2BlockNumber) = asr.getAnchorRoot();

        vm.prank(proxyAdminEnv);
        require(
            IProxy(anchorStateRegistryProxyEnv).implementation() == nextAnchorStateRegistryImpl, "asr impl mismatch"
        );

        require(address(asr.systemConfig()) == systemConfigEnv, "asr system config mismatch");
        require(address(asr.disputeGameFactory()) == disputeGameFactoryProxyEnv, "asr dgf mismatch");
        require(address(asr.anchorGame()) == address(0), "asr anchor game not reset");
        require(Hash.unwrap(startingAnchor.root) == startingAnchorRootEnv, "asr starting anchor root mismatch");
        require(startingAnchor.l2SequenceNumber == startingAnchorL2BlockNumberEnv, "asr starting anchor block mismatch");
        require(Hash.unwrap(currentAnchorRoot) == startingAnchorRootEnv, "asr current anchor root mismatch");
        require(currentAnchorL2BlockNumber == startingAnchorL2BlockNumberEnv, "asr current anchor block mismatch");
        require(GameType.unwrap(asr.respectedGameType()) == GameType.unwrap(gameTypeEnv), "asr game type mismatch");
        require(
            asr.disputeGameFinalityDelaySeconds() == currentAsrDisputeGameFinalityDelaySeconds,
            "asr finality delay mismatch"
        );
        require(asr.initVersion() == currentAsrInitVersion + 1, "asr init version mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
