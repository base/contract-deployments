// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {TEEProverRegistry} from "@base-contracts/src/L1/proofs/tee/TEEProverRegistry.sol";
import {TEEVerifier} from "@base-contracts/src/L1/proofs/tee/TEEVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

/// @notice Cuts the existing TEEProverRegistry over to a preregistered multiproof game type.
contract SetTEEProverRegistryGameType is MultisigScript {
    TEEProverRegistry internal immutable teeProverRegistry;
    address internal immutable ownerSafe;
    GameType internal immutable newGameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    address internal immutable aggregateVerifier;
    address internal immutable teeVerifier;

    constructor() {
        teeProverRegistry = TEEProverRegistry(vm.envAddress("TEE_PROVER_REGISTRY_PROXY"));
        ownerSafe = teeProverRegistry.owner();
        uint256 newGameType = vm.envUint("NEW_GAME_TYPE");
        require(newGameType <= type(uint32).max, "game type overflow");
        newGameTypeEnv = GameType.wrap(uint32(newGameType));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        aggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
        teeVerifier = vm.parseJsonAddress(json, ".teeVerifier");
    }

    function setUp() public view {
        require(
            GameType.unwrap(teeProverRegistry.gameType()) != GameType.unwrap(newGameTypeEnv), "game type already set"
        );
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(
            address(teeProverRegistry.DISPUTE_GAME_FACTORY().gameImpls(newGameTypeEnv)) == aggregateVerifier,
            "registered implementation mismatch"
        );
        require(address(AggregateVerifier(aggregateVerifier).TEE_VERIFIER()) == teeVerifier, "tee verifier mismatch");
        require(AggregateVerifier(aggregateVerifier).TEE_IMAGE_HASH() == teeImageHashEnv, "tee image hash mismatch");
        require(!TEEVerifier(teeVerifier).nullified(), "tee verifier nullified");
        require(
            address(TEEVerifier(teeVerifier).TEE_PROVER_REGISTRY()) == address(teeProverRegistry),
            "tee registry mismatch"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(teeProverRegistry),
            data: abi.encodeCall(TEEProverRegistry.setGameType, (newGameTypeEnv)),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(GameType.unwrap(teeProverRegistry.gameType()) == GameType.unwrap(newGameTypeEnv), "game type mismatch");
        require(teeProverRegistry.getExpectedImageHash() == teeImageHashEnv, "tee image hash mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
