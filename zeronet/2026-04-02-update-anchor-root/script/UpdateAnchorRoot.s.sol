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

interface IProxyAdmin {
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
}

interface IProxy {
    function implementation() external view returns (address);
}

/// @title UpdateAnchorRoot
/// @notice Multisig script that upgrades the AnchorStateRegistry proxy to a new implementation
///         (with reinitializer version bumped from 2 to 3) and reinitializes it with a fresh
///         starting anchor root.
///
///         Call summary:
///         0. Upgrade + reinitialize AnchorStateRegistry proxy (sets new startingAnchorRoot,
///            resets anchorGame, preserves respectedGameType and retirementTimestamp).
contract UpdateAnchorRoot is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal anchorStateRegistryProxyEnv;

    uint32 internal gameTypeEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    address internal newAsrImpl;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        newAsrImpl = vm.parseJsonAddress({json: json, key: ".anchorStateRegistryImpl"});
    }

    /// @dev Builds the single-call batch: upgrade + reinitialize the ASR proxy.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
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
                                root: Hash.wrap(startingAnchorRootEnv),
                                l2SequenceNumber: startingAnchorL2BlockNumberEnv
                            }),
                            GameType.wrap(gameTypeEnv)
                        )
                    )
                )
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        _checkProxyUpgrade();
        _checkAnchorStateRegistry();
    }

    /// @dev Validates that the ASR proxy now points to the new implementation.
    function _checkProxyUpgrade() internal {
        vm.prank(proxyAdminEnv);
        require(IProxy(anchorStateRegistryProxyEnv).implementation() == newAsrImpl, "asr impl mismatch");
    }

    /// @dev Validates the AnchorStateRegistry reinitialization.
    ///      1. Check that systemConfig matches the .env value.
    ///      2. Check that disputeGameFactory matches the .env value.
    ///      3. Check that startingAnchorRoot matches the new .env value.
    ///      4. Check that the starting L2 sequence number matches the new .env value.
    ///      5. Check that respectedGameType is preserved.
    function _checkAnchorStateRegistry() internal view {
        AnchorStateRegistry asr = AnchorStateRegistry(anchorStateRegistryProxyEnv);

        require(address(asr.systemConfig()) == systemConfigEnv, "asr system config mismatch");
        require(address(asr.disputeGameFactory()) == disputeGameFactoryProxyEnv, "asr dgf mismatch");

        Proposal memory startingAnchor = asr.getStartingAnchorRoot();
        require(Hash.unwrap(startingAnchor.root) == startingAnchorRootEnv, "anchor root mismatch");
        require(startingAnchor.l2SequenceNumber == startingAnchorL2BlockNumberEnv, "anchor block mismatch");
        require(GameType.unwrap(asr.respectedGameType()) == gameTypeEnv, "respected game type mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
