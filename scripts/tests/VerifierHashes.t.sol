// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {DisputeGameFactory} from "@base-contracts/src/L1/proofs/DisputeGameFactory.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IDisputeGame} from "interfaces/L1/proofs/IDisputeGame.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";
import {MultisigScript} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {UpdateVerifierHashes} from "../script/UpdateVerifierHashes.s.sol";
import {DeployAggregateVerifier} from "../script/DeployAggregateVerifier.s.sol";
import {SimulationSafe, SimulationMulticall} from "./SimulationFixtures.sol";

contract VerifierHarness is UpdateVerifierHashes {
    function calls() external view returns (Call[] memory) {
        return _buildCalls();
    }

    function postcheck(Vm.AccountAccess[] memory accesses) external view {
        Simulation.Payload memory payload;
        _postCheck(accesses, payload);
    }
}

contract FixtureAnchor {
    IDisputeGameFactory public immutable disputeGameFactory;

    constructor(address factory) {
        disputeGameFactory = IDisputeGameFactory(factory);
    }
}

contract VerifierHashesTest is Test {
    GameType internal constant GAME = GameType.wrap(42);
    address internal constant OWNER = address(0xBEEF);
    address internal constant ADMIN = address(0xAD);
    DisputeGameFactory internal factory;
    AggregateVerifier internal current;
    AggregateVerifier internal replacement;
    VerifierHarness internal script;

    function setUp() public {
        Proxy proxy = new Proxy(ADMIN);
        DisputeGameFactory implementation = new DisputeGameFactory();
        vm.prank(ADMIN);
        proxy.upgradeToAndCall(address(implementation), abi.encodeCall(DisputeGameFactory.initialize, (OWNER)));
        factory = DisputeGameFactory(address(proxy));
        FixtureAnchor anchor = new FixtureAnchor(address(factory));
        current = verifier(anchor, 1, 2, 3);
        replacement = verifier(anchor, 4, 5, 6);
        vm.prank(OWNER);
        factory.setImplementation(GAME, IDisputeGame(address(current)));
        vm.prank(OWNER);
        factory.setImplementation(GameType.wrap(99), IDisputeGame(address(current)));
        vm.createDir("config/local", true);
        configure();
        script = new VerifierHarness();
    }

    function verifier(FixtureAnchor anchor, uint256 tee, uint256 range, uint256 aggregate)
        internal
        returns (AggregateVerifier)
    {
        return new AggregateVerifier(
            GAME,
            IAnchorStateRegistry(address(anchor)),
            IDelayedWETH(payable(address(0x100))),
            IVerifier(address(0x200)),
            IVerifier(address(0x300)),
            bytes32(tee),
            AggregateVerifier.ZkHashes(bytes32(range), bytes32(aggregate)),
            bytes32(uint256(7)),
            8453,
            AggregateVerifier.IntervalConfig(120, 30, 40, 10),
            AggregateVerifier.ScheduleConfig(IProtocolVersions(address(0x400)), 100, 1000, 2)
        );
    }

    function configure() internal {
        vm.setEnv("BASE_CONTRACTS_COMMIT", "8c21f6d08a36b4059ae2bb8938f1e7e758a0e962");
        vm.setEnv("PRESTATE_JSON", "config/local/prestate.json");
        vm.setEnv("PROXY_ADMIN_OWNER", vm.toString(OWNER));
        vm.setEnv("DISPUTE_GAME_FACTORY_PROXY", vm.toString(address(factory)));
        vm.setEnv("GAME_TYPE", "42");
        vm.setEnv("CURRENT_AGGREGATE_VERIFIER", vm.toString(address(current)));
        vm.setEnv("NEW_AGGREGATE_VERIFIER", vm.toString(address(replacement)));
        vm.setEnv("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", vm.toString(bytes32(uint256(4))));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_RANGE_HASH", vm.toString(bytes32(uint256(5))));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", vm.toString(bytes32(uint256(6))));
        vm.setEnv("ADDRESSES_JSON", "config/local/addresses.json");
    }

    function rejectGetter(string memory signature, bytes memory value, string memory reason, bool afterExecution)
        internal
    {
        if (afterExecution) registerReplacement();
        vm.mockCall(address(replacement), abi.encodeWithSignature(signature), value);
        vm.expectRevert(bytes(reason));
        if (afterExecution) script.postcheck(new Vm.AccountAccess[](0));
        else script.calls();
    }

    function registerReplacement() internal {
        vm.prank(OWNER);
        factory.setImplementation(GAME, IDisputeGame(address(replacement)));
    }

    function installSimulationFixtures() internal {
        vm.etch(OWNER, address(new SimulationSafe()).code);
        vm.etch(address(0xCAFE), address(new SimulationSafe()).code);
        vm.etch(address(0xFACE), address(new SimulationSafe()).code);
        vm.etch(0xA8B8CA1d6F0F5Ce63dCEA9121A01b302c5801303, address(new SimulationMulticall()).code);
    }

    function test_nestedSigningPreservesOtherGameTypes() public {
        installSimulationFixtures();
        address[] memory safes = new address[](1);
        safes[0] = address(0xCAFE);
        script.sign(safes);
        assertEq(address(factory.gameImpls(GAME)), address(replacement));
        assertEq(address(factory.gameImpls(GameType.wrap(99))), address(current));
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_exportValidationFixture() public {
        if (!vm.envOr("EXPORT_VALIDATION_FIXTURE", false)) {
            vm.skip(true);
            return;
        }
        address configuredFactory = vm.envAddress("FIXTURE_DISPUTE_GAME_FACTORY_PROXY");
        vm.etch(configuredFactory, address(factory).code);
        vm.store(
            configuredFactory, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1), bytes32(uint256(uint160(ADMIN)))
        );
        DisputeGameFactory implementation = new DisputeGameFactory();
        vm.prank(ADMIN);
        Proxy(payable(configuredFactory))
            .upgradeToAndCall(address(implementation), abi.encodeCall(DisputeGameFactory.initialize, (OWNER)));
        factory = DisputeGameFactory(configuredFactory);
        FixtureAnchor anchor = new FixtureAnchor(address(factory));
        AggregateVerifier live = verifier(anchor, 1, 2, 3);
        address expectedCurrent = vm.envAddress("FIXTURE_CURRENT_AGGREGATE_VERIFIER");
        vm.etch(expectedCurrent, address(live).code);
        current = AggregateVerifier(expectedCurrent);
        vm.prank(OWNER);
        factory.setImplementation(GAME, IDisputeGame(address(current)));
        configure();
        DeployAggregateVerifier deploy = new DeployAggregateVerifier();
        deploy.setUp();
        deploy.run();
        AggregateVerifier deployed = AggregateVerifier(deploy.aggregateVerifier());
        address expectedReplacement = vm.envAddress("FIXTURE_NEW_AGGREGATE_VERIFIER");
        vm.etch(expectedReplacement, address(deployed).code);
        replacement = AggregateVerifier(expectedReplacement);
        configure();
        script = new VerifierHarness();
        script.setUp();
        MultisigScript.Call[] memory calls = script.calls();
        address inner = vm.envAddress("FIXTURE_INNER_SAFE");
        string memory json = vm.serializeBytes("call", "calldata", calls[0].data);
        json = vm.serializeAddress("call", "target", calls[0].target);
        json = vm.serializeAddress("call", "safe", inner);
        json = vm.serializeUint("call", "count", calls.length);
        json = vm.serializeUint("call", "operation", uint256(calls[0].operation));
        json = vm.serializeUint("call", "value", calls[0].value);
        installSimulationFixtures();
        address[] memory safes = new address[](1);
        safes[0] = inner;
        vm.prank(vm.envAddress("FIXTURE_SENDER"));
        script.sign(safes);
        assertEq(address(factory.gameImpls(GAME)), address(replacement));
        vm.writeJson(json, "validation-fixture.json");
    }

    function test_separatePostCheckUsesSavedBaseline() public {
        script.check();
        registerReplacement();
        script.checkAfterExecution();
        vm.mockCall(address(factory), abi.encodeCall(factory.gameCount, ()), abi.encode(uint256(1)));
        vm.expectRevert("game count changed");
        script.checkAfterExecution();
    }

    function test_rejectsUnsupportedPin() public {
        vm.setEnv("BASE_CONTRACTS_COMMIT", "385f21a41f277d287db92fffe88dca41299162ea");
        VerifierHarness unsupported = new VerifierHarness();
        vm.expectRevert("unsupported BASE_CONTRACTS_COMMIT");
        unsupported.calls();
        DeployAggregateVerifier deploy = new DeployAggregateVerifier();
        vm.expectRevert("unsupported BASE_CONTRACTS_COMMIT");
        deploy.run();
    }

    function test_preOwner() public {
        vm.prank(OWNER);
        factory.transferOwnership(address(0xDEAD));
        vm.expectRevert("dgf owner mismatch");
        script.calls();
    }

    function test_preCurrentMapping() public {
        registerReplacement();
        vm.expectRevert("unexpected current aggregate verifier");
        script.calls();
    }

    function test_preReplacementCode() public {
        vm.etch(address(replacement), hex"");
        vm.expectRevert("new aggregate verifier not deployed");
        script.calls();
    }

    function test_preReplacementDiffers() public {
        vm.setEnv("NEW_AGGREGATE_VERIFIER", vm.toString(address(current)));
        VerifierHarness same = new VerifierHarness();
        vm.expectRevert("new aggregate verifier is the current one");
        same.calls();
    }

    function test_preCurrentVersion() public {
        vm.mockCall(address(current), abi.encodeWithSignature("version()"), abi.encode("0.2.0"));
        vm.expectRevert("unexpected current version");
        script.calls();
    }

    function test_preExpectedGameType() public {
        vm.mockCall(address(current), abi.encodeWithSignature("gameType()"), abi.encode(uint32(99)));
        vm.mockCall(address(replacement), abi.encodeWithSignature("gameType()"), abi.encode(uint32(99)));
        vm.expectRevert("current game type mismatch");
        script.calls();
    }

    function test_postRegisteredMapping() public {
        vm.expectRevert("aggregate verifier not registered");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_postOwner() public {
        registerReplacement();
        vm.prank(OWNER);
        factory.transferOwnership(address(0xDEAD));
        vm.expectRevert("dgf owner mismatch");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_postGameArgs() public {
        vm.prank(OWNER);
        factory.setImplementation(GAME, IDisputeGame(address(replacement)), hex"1234");
        vm.expectRevert("aggregate game args changed");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_postGameCount() public {
        registerReplacement();
        vm.mockCall(address(factory), abi.encodeCall(factory.gameCount, ()), abi.encode(uint256(1)));
        vm.expectRevert("game count changed");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_preNonemptyGameArgs() public {
        vm.prank(OWNER);
        factory.setImplementation(GAME, IDisputeGame(address(current)), hex"1234");
        vm.expectRevert("aggregate game args not empty");
        script.calls();
    }

    function test_postReplacementCode() public {
        registerReplacement();
        vm.etch(address(replacement), hex"");
        vm.expectRevert("new aggregate verifier not deployed");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_postCurrentVersion() public {
        registerReplacement();
        vm.mockCall(address(current), abi.encodeWithSignature("version()"), abi.encode("0.2.0"));
        vm.expectRevert("unexpected current version");
        script.postcheck(new Vm.AccountAccess[](0));
    }

    function test_postOtherImplementation() public {
        vm.startStateDiffRecording();
        registerReplacement();
        vm.prank(OWNER);
        factory.setImplementation(GameType.wrap(99), IDisputeGame(address(replacement)));
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        vm.expectRevert("unexpected factory storage write");
        script.postcheck(accesses);
    }

    function test_postOtherFactoryStorage() public {
        vm.startStateDiffRecording();
        registerReplacement();
        vm.prank(OWNER);
        factory.setInitBond(GAME, 1);
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        vm.expectRevert("unexpected factory storage write");
        script.postcheck(accesses);
    }

    function test_deployRejectsAllIdentical() public {
        vm.setEnv("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", vm.toString(current.TEE_IMAGE_HASH()));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_RANGE_HASH", vm.toString(current.ZK_RANGE_HASH()));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", vm.toString(current.ZK_AGGREGATE_HASH()));
        DeployAggregateVerifier deploy = new DeployAggregateVerifier();
        vm.expectRevert("all verifier hashes unchanged");
        deploy.setUp();
    }

    function test_deployOnlyOneHashChanges() public {
        vm.setEnv("AGGREGATE_VERIFIER_ZK_RANGE_HASH", vm.toString(current.ZK_RANGE_HASH()));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", vm.toString(current.ZK_AGGREGATE_HASH()));
        DeployAggregateVerifier deploy = new DeployAggregateVerifier();
        deploy.setUp();
        vm.createDir("config/local", true);
        deploy.run();
        AggregateVerifier deployed = AggregateVerifier(deploy.aggregateVerifier());
        compare(deployed);
        string memory json = vm.readFile("config/local/addresses.json");
        assertEq(vm.parseJsonAddress(json, ".aggregateVerifier"), address(deployed));
        assertGt(vm.parseJsonBytes(json, ".aggregateVerifierConstructorArgs").length, 0);
    }

    function test_preVersion() public {
        rejectGetter("version()", abi.encode("0.2.0"), "new version mismatch", false);
    }

    function test_postVersion() public {
        rejectGetter("version()", abi.encode("0.2.0"), "new version mismatch", true);
    }

    function test_preTeeHash() public {
        rejectGetter("TEE_IMAGE_HASH()", abi.encode(bytes32(uint256(9))), "tee image hash mismatch", false);
    }

    function test_postTeeHash() public {
        rejectGetter("TEE_IMAGE_HASH()", abi.encode(bytes32(uint256(9))), "tee image hash mismatch", true);
    }

    function test_preRangeHash() public {
        rejectGetter("ZK_RANGE_HASH()", abi.encode(bytes32(uint256(9))), "zk range hash mismatch", false);
    }

    function test_postRangeHash() public {
        rejectGetter("ZK_RANGE_HASH()", abi.encode(bytes32(uint256(9))), "zk range hash mismatch", true);
    }

    function test_preAggregateHash() public {
        rejectGetter("ZK_AGGREGATE_HASH()", abi.encode(bytes32(uint256(9))), "zk aggregate hash mismatch", false);
    }

    function test_postAggregateHash() public {
        rejectGetter("ZK_AGGREGATE_HASH()", abi.encode(bytes32(uint256(9))), "zk aggregate hash mismatch", true);
    }

    function test_preGameType() public {
        rejectGetter("gameType()", abi.encode(uint32(9)), "game type mismatch", false);
    }

    function test_postGameType() public {
        rejectGetter("gameType()", abi.encode(uint32(9)), "game type mismatch", true);
    }

    function test_preAnchor() public {
        rejectGetter("anchorStateRegistry()", abi.encode(address(9)), "asr mismatch", false);
    }

    function test_postAnchor() public {
        rejectGetter("anchorStateRegistry()", abi.encode(address(9)), "asr mismatch", true);
    }

    function test_preFactory() public {
        rejectGetter("DISPUTE_GAME_FACTORY()", abi.encode(address(9)), "dgf mismatch", false);
    }

    function test_postFactory() public {
        rejectGetter("DISPUTE_GAME_FACTORY()", abi.encode(address(9)), "dgf mismatch", true);
    }

    function test_preWeth() public {
        rejectGetter("DELAYED_WETH()", abi.encode(address(9)), "delayed weth mismatch", false);
    }

    function test_postWeth() public {
        rejectGetter("DELAYED_WETH()", abi.encode(address(9)), "delayed weth mismatch", true);
    }

    function test_preTeeVerifier() public {
        rejectGetter("TEE_VERIFIER()", abi.encode(address(9)), "tee verifier mismatch", false);
    }

    function test_postTeeVerifier() public {
        rejectGetter("TEE_VERIFIER()", abi.encode(address(9)), "tee verifier mismatch", true);
    }

    function test_preZkVerifier() public {
        rejectGetter("ZK_VERIFIER()", abi.encode(address(9)), "zk verifier mismatch", false);
    }

    function test_postZkVerifier() public {
        rejectGetter("ZK_VERIFIER()", abi.encode(address(9)), "zk verifier mismatch", true);
    }

    function test_preConfigHash() public {
        rejectGetter("CONFIG_HASH()", abi.encode(bytes32(uint256(9))), "config hash mismatch", false);
    }

    function test_postConfigHash() public {
        rejectGetter("CONFIG_HASH()", abi.encode(bytes32(uint256(9))), "config hash mismatch", true);
    }

    function test_preChainId() public {
        rejectGetter("L2_CHAIN_ID()", abi.encode(uint256(9)), "l2 chain id mismatch", false);
    }

    function test_postChainId() public {
        rejectGetter("L2_CHAIN_ID()", abi.encode(uint256(9)), "l2 chain id mismatch", true);
    }

    function test_preSlowBlock() public {
        rejectGetter("SLOW_BLOCK_INTERVAL()", abi.encode(uint256(9)), "slow block interval mismatch", false);
    }

    function test_postSlowBlock() public {
        rejectGetter("SLOW_BLOCK_INTERVAL()", abi.encode(uint256(9)), "slow block interval mismatch", true);
    }

    function test_preSlowIntermediate() public {
        rejectGetter("SLOW_INTERMEDIATE_BLOCK_INTERVAL()", abi.encode(uint256(9)), "slow intermediate mismatch", false);
    }

    function test_postSlowIntermediate() public {
        rejectGetter("SLOW_INTERMEDIATE_BLOCK_INTERVAL()", abi.encode(uint256(9)), "slow intermediate mismatch", true);
    }

    function test_preFastBlock() public {
        rejectGetter("FAST_BLOCK_INTERVAL()", abi.encode(uint256(9)), "fast block interval mismatch", false);
    }

    function test_postFastBlock() public {
        rejectGetter("FAST_BLOCK_INTERVAL()", abi.encode(uint256(9)), "fast block interval mismatch", true);
    }

    function test_preFastIntermediate() public {
        rejectGetter("FAST_INTERMEDIATE_BLOCK_INTERVAL()", abi.encode(uint256(9)), "fast intermediate mismatch", false);
    }

    function test_postFastIntermediate() public {
        rejectGetter("FAST_INTERMEDIATE_BLOCK_INTERVAL()", abi.encode(uint256(9)), "fast intermediate mismatch", true);
    }

    function test_preProtocol() public {
        rejectGetter("PROTOCOL_VERSIONS()", abi.encode(address(9)), "protocol versions mismatch", false);
    }

    function test_postProtocol() public {
        rejectGetter("PROTOCOL_VERSIONS()", abi.encode(address(9)), "protocol versions mismatch", true);
    }

    function test_preGenesisBlock() public {
        rejectGetter("L2_GENESIS_BLOCK_NUMBER()", abi.encode(uint256(9)), "genesis block mismatch", false);
    }

    function test_postGenesisBlock() public {
        rejectGetter("L2_GENESIS_BLOCK_NUMBER()", abi.encode(uint256(9)), "genesis block mismatch", true);
    }

    function test_preGenesisTimestamp() public {
        rejectGetter("L2_GENESIS_TIMESTAMP()", abi.encode(uint64(9)), "genesis timestamp mismatch", false);
    }

    function test_postGenesisTimestamp() public {
        rejectGetter("L2_GENESIS_TIMESTAMP()", abi.encode(uint64(9)), "genesis timestamp mismatch", true);
    }

    function test_preBlockTime() public {
        rejectGetter("L2_BLOCK_TIME()", abi.encode(uint64(9)), "l2 block time mismatch", false);
    }

    function test_postBlockTime() public {
        rejectGetter("L2_BLOCK_TIME()", abi.encode(uint64(9)), "l2 block time mismatch", true);
    }

    function test_preRootCount() public {
        rejectGetter(
            "intermediateOutputRootsCount()", abi.encode(uint256(9)), "intermediate root count mismatch", false
        );
    }

    function test_postRootCount() public {
        rejectGetter("intermediateOutputRootsCount()", abi.encode(uint256(9)), "intermediate root count mismatch", true);
    }

    function test_deployRejectsZeroTee() public {
        rejectZero("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
    }

    function test_deployRejectsZeroRange() public {
        rejectZero("AGGREGATE_VERIFIER_ZK_RANGE_HASH", "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
    }

    function test_deployRejectsZeroAggregate() public {
        rejectZero("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");
    }

    function rejectZero(string memory name, string memory reason) internal {
        vm.setEnv(name, vm.toString(bytes32(0)));
        DeployAggregateVerifier deploy = new DeployAggregateVerifier();
        vm.expectRevert(bytes(reason));
        deploy.run();
    }

    function compare(AggregateVerifier deployed) internal view {
        assertEq(deployed.version(), "0.3.0");
        assertEq(deployed.TEE_IMAGE_HASH(), bytes32(uint256(4)));
        assertEq(deployed.ZK_RANGE_HASH(), current.ZK_RANGE_HASH());
        assertEq(deployed.ZK_AGGREGATE_HASH(), current.ZK_AGGREGATE_HASH());
        assertEq(GameType.unwrap(deployed.gameType()), GameType.unwrap(current.gameType()));
        assertEq(address(deployed.anchorStateRegistry()), address(current.anchorStateRegistry()));
        assertEq(address(deployed.DISPUTE_GAME_FACTORY()), address(current.DISPUTE_GAME_FACTORY()));
        assertEq(address(deployed.DELAYED_WETH()), address(current.DELAYED_WETH()));
        assertEq(address(deployed.TEE_VERIFIER()), address(current.TEE_VERIFIER()));
        assertEq(address(deployed.ZK_VERIFIER()), address(current.ZK_VERIFIER()));
        assertEq(deployed.CONFIG_HASH(), current.CONFIG_HASH());
        assertEq(deployed.L2_CHAIN_ID(), current.L2_CHAIN_ID());
        assertEq(deployed.SLOW_BLOCK_INTERVAL(), current.SLOW_BLOCK_INTERVAL());
        assertEq(deployed.SLOW_INTERMEDIATE_BLOCK_INTERVAL(), current.SLOW_INTERMEDIATE_BLOCK_INTERVAL());
        assertEq(deployed.FAST_BLOCK_INTERVAL(), current.FAST_BLOCK_INTERVAL());
        assertEq(deployed.FAST_INTERMEDIATE_BLOCK_INTERVAL(), current.FAST_INTERMEDIATE_BLOCK_INTERVAL());
        assertEq(address(deployed.PROTOCOL_VERSIONS()), address(current.PROTOCOL_VERSIONS()));
        assertEq(deployed.L2_GENESIS_BLOCK_NUMBER(), current.L2_GENESIS_BLOCK_NUMBER());
        assertEq(deployed.L2_GENESIS_TIMESTAMP(), current.L2_GENESIS_TIMESTAMP());
        assertEq(deployed.L2_BLOCK_TIME(), current.L2_BLOCK_TIME());
        assertEq(deployed.intermediateOutputRootsCount(), current.intermediateOutputRootsCount());
    }
}
