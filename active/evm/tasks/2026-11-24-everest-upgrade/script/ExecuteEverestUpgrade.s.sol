// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IDisputeGame} from "interfaces/L1/proofs/IDisputeGame.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

// abi.encodeCall cannot disambiguate the factory's overloaded setter in Solidity 0.8.15.
interface IImplementationSetter {
    function setImplementation(GameType gameType, IDisputeGame implementation) external;
}

/// @notice Prepares a network for Everest in one ProxyAdmin-owner transaction:
///         1. registers an AggregateVerifier 0.3.0 carrying the Everest proof program hashes for the
///            multiproof game type, and
///         2. registers Everest as upgrade id 14 in ProtocolVersions, scheduling its activation and
///            raising the minimum protocol version.
/// @dev Games bind `ProtocolVersions.activatedScheduleId(claimTimestamp)`, so the registered activation
///      must match the one compiled into the prover build the new hashes come from.
contract ExecuteEverestUpgrade is MultisigScript {
    using stdStorage for StdStorage;

    uint256 internal constant EVEREST_UPGRADE_ID = 14;
    string internal constant VERSION = "0.3.0";

    // Task config from .env.
    address internal immutable ownerSafe;
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable currentAggregateVerifier;
    address internal immutable newAggregateVerifier;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;
    uint64 internal immutable everestActivationTimestamp;
    uint256 internal immutable currentMinimumProtocolVersion;
    uint256 internal immutable newMinimumProtocolVersion;

    // Live state captured at construction and re-asserted after execution.
    address internal immutable protocolVersions;
    uint256 internal immutable gameCountBefore;
    bytes32 internal immutable implementationSlot;
    bytes32 internal immutable scheduleHashBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        uint256 configuredGameType = vm.envUint("GAME_TYPE");
        require(configuredGameType <= type(uint32).max, "game type overflow");
        gameType = GameType.wrap(uint32(configuredGameType));
        currentAggregateVerifier = vm.envAddress("CURRENT_AGGREGATE_VERIFIER");
        newAggregateVerifier = vm.envAddress("NEW_AGGREGATE_VERIFIER");
        teeImageHash = vm.envBytes32("AGGREGATE_VERIFIER_TEE_IMAGE_HASH");
        zkRangeHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_RANGE_HASH");
        zkAggregateHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH");
        uint256 configuredActivation = vm.envUint("EVEREST_ACTIVATION_TIMESTAMP");
        require(configuredActivation <= type(uint64).max, "everest activation overflow");
        everestActivationTimestamp = uint64(configuredActivation);
        currentMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION");
        newMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");

        protocolVersions = address(AggregateVerifier(currentAggregateVerifier).PROTOCOL_VERSIONS());
        gameCountBefore = IDisputeGameFactory(disputeGameFactory).gameCount();
        implementationSlot =
            bytes32(stdstore.target(disputeGameFactory).sig("gameImpls(uint32)").with_key(configuredGameType).find());
        scheduleHashBefore = keccak256(abi.encode(IProtocolVersions(protocolVersions).getSchedule()));
    }

    function setUp() public view {
        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        // Both calls are authorized by the same Safe.
        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(registry.proxyAdminOwner() == ownerSafe, "protocol versions owner mismatch");

        // AggregateVerifier swap.
        require(address(dgf.gameImpls(gameType)) == currentAggregateVerifier, "unexpected current aggregate verifier");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args not empty");
        _assertNewVerifier();

        // Everest registration.
        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == EVEREST_UPGRADE_ID, "unexpected upgrade count");
        require(everestActivationTimestamp > schedule[schedule.length - 1], "everest must activate after denim");
        require(
            everestActivationTimestamp >= uint64(block.timestamp) + registry.MIN_NOTICE(),
            "everest activation inside MIN_NOTICE"
        );
        require(
            registry.minimumProtocolVersion() == currentMinimumProtocolVersion,
            "current minimum protocol version mismatch"
        );
        require(newMinimumProtocolVersion > currentMinimumProtocolVersion, "minimum protocol version not increased");
        require(newMinimumProtocolVersion <= type(uint128).max, "minimum protocol version too large");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        // Swap the verifier first so the Everest hashes are live before the schedule gains the Everest entry.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(
                IImplementationSetter.setImplementation, (gameType, IDisputeGame(newAggregateVerifier))
            ),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: protocolVersions,
            data: abi.encodeCall(
                IProtocolVersions.registerUpgrade, (everestActivationTimestamp, newMinimumProtocolVersion)
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        require(dgf.owner() == ownerSafe, "dgf owner changed");
        require(address(dgf.gameImpls(gameType)) == newAggregateVerifier, "aggregate verifier not registered");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args changed");
        require(dgf.gameCount() == gameCountBefore, "game count changed");
        _assertNewVerifier();

        // The only factory write must move the target game type from the current to the new verifier.
        for (uint256 i; i < accesses.length; i++) {
            for (uint256 j; j < accesses[i].storageAccesses.length; j++) {
                Vm.StorageAccess memory access = accesses[i].storageAccesses[j];
                if (access.account != disputeGameFactory || !access.isWrite || access.reverted) continue;
                require(access.slot == implementationSlot, "unexpected factory storage write");
                require(
                    access.previousValue == bytes32(uint256(uint160(currentAggregateVerifier)))
                        && access.newValue == bytes32(uint256(uint160(newAggregateVerifier))),
                    "unexpected implementation transition"
                );
            }
        }

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == EVEREST_UPGRADE_ID + 1, "everest not registered");
        require(schedule[EVEREST_UPGRADE_ID] == everestActivationTimestamp, "everest activation mismatch");
        uint64[] memory previous = new uint64[](EVEREST_UPGRADE_ID);
        for (uint256 i; i < EVEREST_UPGRADE_ID; i++) {
            previous[i] = schedule[i];
        }
        require(keccak256(abi.encode(previous)) == scheduleHashBefore, "previous upgrades changed");
        require(registry.minimumProtocolVersion() == newMinimumProtocolVersion, "minimum protocol version not updated");
    }

    /// @dev Checks the new verifier's hashes against config and every other immutable against the current
    ///      verifier.
    function _assertNewVerifier() internal view {
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);

        require(_eq(current.version(), VERSION), "unexpected current version");
        require(GameType.unwrap(current.gameType()) == GameType.unwrap(gameType), "current game type mismatch");
        require(address(current.DISPUTE_GAME_FACTORY()) == disputeGameFactory, "current dgf mismatch");
        require(newAggregateVerifier.code.length != 0, "new aggregate verifier not deployed");
        require(newAggregateVerifier != currentAggregateVerifier, "new aggregate verifier is the current one");
        require(_eq(av.version(), VERSION), "new version mismatch");

        require(teeImageHash != bytes32(0), "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
        require(zkRangeHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
        require(zkAggregateHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");
        require(av.TEE_IMAGE_HASH() == teeImageHash, "tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "zk aggregate hash mismatch");

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(current.gameType()), "game type mismatch");
        require(address(av.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()), "dgf mismatch");
        require(address(av.DELAYED_WETH()) == address(current.DELAYED_WETH()), "delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == address(current.TEE_VERIFIER()), "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == address(current.ZK_VERIFIER()), "zk verifier mismatch");
        require(av.CONFIG_HASH() == current.CONFIG_HASH(), "config hash mismatch");
        require(av.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(av.SLOW_BLOCK_INTERVAL() == current.SLOW_BLOCK_INTERVAL(), "slow block interval mismatch");
        require(
            av.SLOW_INTERMEDIATE_BLOCK_INTERVAL() == current.SLOW_INTERMEDIATE_BLOCK_INTERVAL(),
            "slow intermediate mismatch"
        );
        require(av.FAST_BLOCK_INTERVAL() == current.FAST_BLOCK_INTERVAL(), "fast block interval mismatch");
        require(
            av.FAST_INTERMEDIATE_BLOCK_INTERVAL() == current.FAST_INTERMEDIATE_BLOCK_INTERVAL(),
            "fast intermediate mismatch"
        );
        require(address(av.PROTOCOL_VERSIONS()) == protocolVersions, "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == current.L2_GENESIS_BLOCK_NUMBER(), "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == current.L2_GENESIS_TIMESTAMP(), "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == current.L2_BLOCK_TIME(), "l2 block time mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
