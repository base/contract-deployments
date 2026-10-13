// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

import {IAggregateVerifierV020} from "./IAggregateVerifierV020.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface IDisputeGameFactoryAdmin {
    function gameArgs(GameType gameType) external view returns (bytes memory);
    function gameCount() external view returns (uint256);
    function gameImpls(GameType gameType) external view returns (address);
    function owner() external view returns (address);
    function setImplementation(GameType gameType, address impl) external;
}

interface IProtocolVersions {
    function MIN_NOTICE() external view returns (uint64);
    function getSchedule() external view returns (uint64[] memory);
    function minimumProtocolVersion() external view returns (uint256);
    function registerUpgrade(uint64 timestamp, uint256 minProtocolVersion) external returns (uint256);
}

/// @notice Prepares Zeronet for Denim in one ProxyAdmin-owner transaction:
///         1. registers AggregateVerifier 0.3.0 for the multiproof game type, and
///         2. registers Denim as upgrade id 13 in ProtocolVersions, which schedules the hardfork for
///            the nodes and the 200ms cadence switch for the new verifier, and raises the minimum
///            protocol version.
/// @dev The new verifier reads the Denim activation from ProtocolVersions index 13 and behaves like
///      0.2.0 until then, so swapping it in before the activation is safe.
contract ExecuteDenimUpgrade is MultisigScript {
    uint256 internal constant DENIM_UPGRADE_ID = 13;

    string internal constant OLD_VERSION = "0.2.0";
    string internal constant NEW_VERSION = "0.3.0";

    // Task config from .env.
    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable oldAggregateVerifier;
    address internal immutable newAggregateVerifier;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;
    uint256 internal immutable fastBlockInterval;
    uint256 internal immutable fastIntermediateBlockInterval;
    uint64 internal immutable denimActivationTimestamp;
    uint256 internal immutable currentMinimumProtocolVersion;
    uint256 internal immutable newMinimumProtocolVersion;

    // Live state captured at construction and re-asserted after execution.
    address internal immutable protocolVersions;
    uint256 internal immutable gameCountBefore;
    bytes32 internal immutable scheduleHashBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameType = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        oldAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");
        newAggregateVerifier = vm.envAddress("NEW_AGGREGATE_VERIFIER");
        teeImageHash = vm.envBytes32("AGGREGATE_VERIFIER_TEE_IMAGE_HASH");
        zkRangeHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_RANGE_HASH");
        zkAggregateHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH");
        fastBlockInterval = vm.envUint("FAST_BLOCK_INTERVAL");
        fastIntermediateBlockInterval = vm.envUint("FAST_INTERMEDIATE_BLOCK_INTERVAL");
        denimActivationTimestamp = uint64(vm.envUint("PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP"));
        currentMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION");
        newMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");

        address registry = IAggregateVerifierV020(oldAggregateVerifier).PROTOCOL_VERSIONS();
        protocolVersions = registry;
        gameCountBefore = IDisputeGameFactoryAdmin(disputeGameFactory).gameCount();
        scheduleHashBefore = keccak256(abi.encode(IProtocolVersions(registry).getSchedule()));
    }

    function setUp() public view {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        // Both calls are authorized against the same Safe: the factory owner and the ProxyAdmin owner.
        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");

        // AggregateVerifier swap.
        require(dgf.gameImpls(gameType) == oldAggregateVerifier, "unexpected current aggregate verifier");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args not empty");
        require(_eq(IAggregateVerifierV020(oldAggregateVerifier).version(), OLD_VERSION), "unexpected current version");
        require(newAggregateVerifier.code.length != 0, "new aggregate verifier not deployed");
        require(newAggregateVerifier != oldAggregateVerifier, "new aggregate verifier is the current one");
        require(_eq(AggregateVerifier(newAggregateVerifier).version(), NEW_VERSION), "new version mismatch");
        _assertNewVerifier();

        // Denim registration.
        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == DENIM_UPGRADE_ID, "unexpected upgrade count");
        require(denimActivationTimestamp > schedule[schedule.length - 1], "denim must activate after cobalt");
        require(
            denimActivationTimestamp >= uint64(block.timestamp) + registry.MIN_NOTICE(),
            "denim activation inside MIN_NOTICE"
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

        // Swap the verifier first so it is live before the schedule it reads gains the Denim entry.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (gameType, newAggregateVerifier)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: protocolVersions,
            data: abi.encodeCall(
                IProtocolVersions.registerUpgrade, (denimActivationTimestamp, newMinimumProtocolVersion)
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        require(dgf.gameImpls(gameType) == newAggregateVerifier, "aggregate verifier not registered");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args changed");
        require(dgf.gameCount() == gameCountBefore, "game count changed");

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == DENIM_UPGRADE_ID + 1, "denim not registered");
        require(schedule[DENIM_UPGRADE_ID] == denimActivationTimestamp, "denim activation mismatch");
        uint64[] memory previous = new uint64[](DENIM_UPGRADE_ID);
        for (uint256 i = 0; i < DENIM_UPGRADE_ID; i++) {
            previous[i] = schedule[i];
        }
        require(keccak256(abi.encode(previous)) == scheduleHashBefore, "previous upgrades changed");
        require(registry.minimumProtocolVersion() == newMinimumProtocolVersion, "minimum protocol version not updated");

        // The new verifier must switch to the fast intervals exactly at the first Denim block.
        _assertNewVerifier();
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);
        uint256 firstFastBlock = av.L2_GENESIS_BLOCK_NUMBER()
            + _divUp(denimActivationTimestamp - av.L2_GENESIS_TIMESTAMP(), av.L2_BLOCK_TIME());
        (uint256 blockInterval, uint256 intermediateBlockInterval) = av.intervalsForStartingBlock(firstFastBlock - 1);
        require(blockInterval == av.SLOW_BLOCK_INTERVAL(), "pre-denim block interval mismatch");
        require(intermediateBlockInterval == av.SLOW_INTERMEDIATE_BLOCK_INTERVAL(), "pre-denim intermediate mismatch");
        (blockInterval, intermediateBlockInterval) = av.intervalsForStartingBlock(firstFastBlock);
        require(blockInterval == fastBlockInterval, "post-denim block interval mismatch");
        require(intermediateBlockInterval == fastIntermediateBlockInterval, "post-denim intermediate mismatch");
    }

    /// @dev Checks the new verifier's hashes and fast intervals against config and every other immutable
    ///      against the live verifier.
    function _assertNewVerifier() internal view {
        IAggregateVerifierV020 live = IAggregateVerifierV020(oldAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);

        require(av.TEE_IMAGE_HASH() == teeImageHash, "tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "zk aggregate hash mismatch");
        require(av.FAST_BLOCK_INTERVAL() == fastBlockInterval, "fast block interval mismatch");
        require(av.FAST_INTERMEDIATE_BLOCK_INTERVAL() == fastIntermediateBlockInterval, "fast intermediate mismatch");

        require(av.SLOW_BLOCK_INTERVAL() == live.BLOCK_INTERVAL(), "slow block interval mismatch");
        require(
            av.SLOW_INTERMEDIATE_BLOCK_INTERVAL() == live.INTERMEDIATE_BLOCK_INTERVAL(), "slow intermediate mismatch"
        );
        require(GameType.unwrap(av.gameType()) == GameType.unwrap(live.gameType()), "game type mismatch");
        require(address(av.anchorStateRegistry()) == live.anchorStateRegistry(), "asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == live.DISPUTE_GAME_FACTORY(), "dgf mismatch");
        require(address(av.DELAYED_WETH()) == live.DELAYED_WETH(), "delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == live.TEE_VERIFIER(), "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == live.ZK_VERIFIER(), "zk verifier mismatch");
        require(av.CONFIG_HASH() == live.CONFIG_HASH(), "config hash mismatch");
        require(av.L2_CHAIN_ID() == live.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(address(av.PROTOCOL_VERSIONS()) == live.PROTOCOL_VERSIONS(), "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == live.L2_GENESIS_BLOCK_NUMBER(), "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == live.L2_GENESIS_TIMESTAMP(), "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == live.L2_BLOCK_TIME(), "l2 block time mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
