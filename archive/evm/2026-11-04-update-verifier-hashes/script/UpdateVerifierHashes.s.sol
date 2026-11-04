// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IDisputeGame} from "interfaces/L1/proofs/IDisputeGame.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

// abi.encodeCall cannot disambiguate the factory's overloaded setter in Solidity 0.8.15.
interface IImplementationSetter {
    function setImplementation(GameType gameType, IDisputeGame implementation) external;
}

contract UpdateVerifierHashes is MultisigScript {
    using stdStorage for StdStorage;
    string internal constant VERSION = "0.3.0";

    bytes32 internal immutable contractsCommit;
    address internal immutable ownerSafe;
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable currentAggregateVerifier;
    address internal immutable newAggregateVerifier;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;

    bytes32 internal immutable gameArgsHashBefore;
    bytes32 internal immutable implementationSlot;
    uint256 internal immutable gameCountBefore;

    constructor() {
        contractsCommit = keccak256(bytes(vm.envString("BASE_CONTRACTS_COMMIT")));
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

        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactory);
        gameCountBefore = dgf.gameCount();
        gameArgsHashBefore = keccak256(dgf.gameArgs(gameType));
        implementationSlot =
            bytes32(stdstore.target(disputeGameFactory).sig("gameImpls(uint32)").with_key(configuredGameType).find());
    }

    function setUp() public view virtual {
        _preCheck();
    }

    function _preCheck() internal view {
        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactory);

        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(address(dgf.gameImpls(gameType)) == currentAggregateVerifier, "unexpected current aggregate verifier");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args not empty");
        _assertNewVerifier();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        _preCheck();
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(
                IImplementationSetter.setImplementation, (gameType, IDisputeGame(newAggregateVerifier))
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        _assertPostState(gameCountBefore, gameArgsHashBefore);
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
    }

    function _assertPostState(uint256 count, bytes32 argsHash) internal view {
        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactory);
        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(address(dgf.gameImpls(gameType)) == newAggregateVerifier, "aggregate verifier not registered");
        require(keccak256(dgf.gameArgs(gameType)) == argsHash, "aggregate game args changed");
        require(dgf.gameCount() == count, "game count changed");

        _assertNewVerifier();
    }

    function check() external {
        _preCheck();
        string memory json = vm.serializeUint("prestate", "gameCount", gameCountBefore);
        json = vm.serializeBytes32("prestate", "gameArgsHash", gameArgsHashBefore);
        vm.writeJson(json, vm.envString("PRESTATE_JSON"));
    }

    function checkAfterExecution() public view {
        string memory json = vm.readFile(vm.envString("PRESTATE_JSON"));
        _assertPostState(vm.parseJsonUint(json, ".gameCount"), vm.parseJsonBytes32(json, ".gameArgsHash"));
    }

    function _assertNewVerifier() internal view {
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);
        require(
            contractsCommit == keccak256("8c21f6d08a36b4059ae2bb8938f1e7e758a0e962"),
            "unsupported BASE_CONTRACTS_COMMIT"
        );
        require(_eq(current.version(), VERSION), "unexpected current version");
        require(GameType.unwrap(current.gameType()) == GameType.unwrap(gameType), "current game type mismatch");
        require(address(current.DISPUTE_GAME_FACTORY()) == disputeGameFactory, "current dgf mismatch");
        require(newAggregateVerifier.code.length != 0, "new aggregate verifier not deployed");
        require(newAggregateVerifier != currentAggregateVerifier, "new aggregate verifier is the current one");
        require(_eq(av.version(), VERSION), "new version mismatch");
        require(teeImageHash != bytes32(0), "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
        require(zkRangeHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
        require(zkAggregateHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");
        require(
            teeImageHash != current.TEE_IMAGE_HASH() || zkRangeHash != current.ZK_RANGE_HASH()
                || zkAggregateHash != current.ZK_AGGREGATE_HASH(),
            "all verifier hashes unchanged"
        );

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
        require(address(av.PROTOCOL_VERSIONS()) == address(current.PROTOCOL_VERSIONS()), "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == current.L2_GENESIS_BLOCK_NUMBER(), "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == current.L2_GENESIS_TIMESTAMP(), "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == current.L2_BLOCK_TIME(), "l2 block time mismatch");
        require(
            av.intermediateOutputRootsCount() == current.intermediateOutputRootsCount(),
            "intermediate root count mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

contract VerifyVerifierHashes is UpdateVerifierHashes {
    function setUp() public view override {
        checkAfterExecution();
    }
}
