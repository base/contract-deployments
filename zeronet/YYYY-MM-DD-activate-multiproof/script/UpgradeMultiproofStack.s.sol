// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {GameType, Hash, Proposal} from "@base-contracts/src/dispute/lib/Types.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";

interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
}

interface IProxy {
    function implementation() external view returns (address);
}

interface IDisputeGameFactoryAdmin {
    function gameImpls(GameType gameType) external view returns (address);
    function initBonds(GameType gameType) external view returns (uint256);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
    function setInitBond(GameType gameType, uint256 initBond) external;
}

contract UpgradeMultiproofStack is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal optimismPortalEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal anchorStateRegistryProxyEnv;

    uint32 internal gameTypeEnv;
    uint256 internal initBondEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    address internal newAggregateVerifier;
    address internal newOptimismPortalImpl;
    address internal newDgfImpl;
    address internal newAsrImpl;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        optimismPortalEnv = vm.envAddress("OPTIMISM_PORTAL");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        initBondEnv = vm.envUint("INIT_BOND");
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newAggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
        newOptimismPortalImpl = vm.parseJsonAddress(json, ".optimismPortal2Impl");
        newDgfImpl = vm.parseJsonAddress(json, ".disputeGameFactoryImpl");
        newAsrImpl = vm.parseJsonAddress(json, ".anchorStateRegistryImpl");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        vm.prank(proxyAdminEnv);
        require(IProxy(optimismPortalEnv).implementation() == newOptimismPortalImpl, "portal impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(disputeGameFactoryProxyEnv).implementation() == newDgfImpl, "dgf impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(anchorStateRegistryProxyEnv).implementation() == newAsrImpl, "asr impl mismatch");

        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(dgf.gameImpls(GameType.wrap(gameTypeEnv)) == newAggregateVerifier, "game impl mismatch");
        require(dgf.initBonds(GameType.wrap(gameTypeEnv)) == initBondEnv, "init bond mismatch");

        Proposal memory startingAnchor = AnchorStateRegistry(anchorStateRegistryProxyEnv).getStartingAnchorRoot();
        require(Hash.unwrap(startingAnchor.root) == startingAnchorRootEnv, "anchor root mismatch");
        require(startingAnchor.l2SequenceNumber == startingAnchorL2BlockNumberEnv, "anchor block mismatch");
        require(
            GameType.unwrap(AnchorStateRegistry(anchorStateRegistryProxyEnv).respectedGameType()) == gameTypeEnv,
            "respected game type mismatch"
        );
        require(AnchorStateRegistry(anchorStateRegistryProxyEnv).retirementTimestamp() > 0, "retirement not set");
        require(
            address(OptimismPortal2(payable(optimismPortalEnv)).anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "portal asr mismatch"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](7);

        // 0. Upgrade the OptimismPortal2 proxy to the new implementation.
        //    No reinitializer call is needed in this activation.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (optimismPortalEnv, newOptimismPortalImpl)),
            value: 0
        });

        // 1. Upgrade the DisputeGameFactory proxy to the new implementation.
        //    No reinitializer call is needed for DGF in this activation.
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (disputeGameFactoryProxyEnv, newDgfImpl)),
            value: 0
        });

        // 2. Upgrade the AnchorStateRegistry proxy and rerun initialize to seed the
        //    starting anchor root, wire the DGF dependency, and set the initial game type.
        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    anchorStateRegistryProxyEnv,
                    newAsrImpl,
                    abi.encodeCall(
                        AnchorStateRegistry.initialize,
                        (
                            ISystemConfig(systemConfigEnv),
                            IDisputeGameFactory(disputeGameFactoryProxyEnv),
                            Proposal({
                                root: Hash.wrap(startingAnchorRootEnv), l2SequenceNumber: startingAnchorL2BlockNumberEnv
                            }),
                            GameType.wrap(gameTypeEnv)
                        )
                    )
                )
            ),
            value: 0
        });

        // 3. Register the newly deployed AggregateVerifier as the implementation for the
        //    configured multiproof game type in the DisputeGameFactory.
        calls[3] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (GameType.wrap(gameTypeEnv), newAggregateVerifier, "")
            ),
            value: 0
        });

        // 4. Set the init bond required to create games of the new multiproof type.
        calls[4] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setInitBond, (GameType.wrap(gameTypeEnv), initBondEnv)),
            value: 0
        });

        // 5. Retire any pre-cutover games so older disputes cannot remain respected after
        //    the new multiproof configuration is activated.
        calls[5] = Call({
            operation: Enum.Operation.Call,
            target: anchorStateRegistryProxyEnv,
            data: abi.encodeCall(AnchorStateRegistry.updateRetirementTimestamp, ()),
            value: 0
        });

        // 6. Finalize the cutover by marking the new multiproof game type as the respected
        //    game type used by the AnchorStateRegistry.
        calls[6] = Call({
            operation: Enum.Operation.Call,
            target: anchorStateRegistryProxyEnv,
            data: abi.encodeCall(AnchorStateRegistry.setRespectedGameType, (GameType.wrap(gameTypeEnv))),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
