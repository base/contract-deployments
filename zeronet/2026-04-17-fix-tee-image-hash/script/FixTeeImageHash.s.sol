// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Swaps the game-type 621 implementation in the DisputeGameFactory to the newly
/// deployed AggregateVerifier carrying the corrected TEE_IMAGE_HASH.
contract FixTeeImageHash is MultisigScript {
    address internal ownerSafeEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal existingAggregateVerifierEnv;
    bytes32 internal newTeeImageHashEnv;

    address internal newAggregateVerifier;
    GameType internal gameType;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        existingAggregateVerifierEnv = vm.envAddress("EXISTING_AGGREGATE_VERIFIER");
        newTeeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        require(newAggregateVerifier != existingAggregateVerifierEnv, "new aggregate verifier equals existing");

        AggregateVerifier newAv = AggregateVerifier(newAggregateVerifier);
        gameType = newAv.gameType();

        // Guard: the freshly deployed AggregateVerifier must carry the target hash.
        require(newAv.TEE_IMAGE_HASH() == newTeeImageHashEnv, "new aggregate tee image hash mismatch");

        // Guard: the AggregateVerifier currently registered in the DGF for this game type must be
        // the same one the deploy script cloned. The deploy script already asserted that contract
        // carries CURRENT_TEE_IMAGE_HASH, so this transitively validates the prestate we are replacing.
        require(
            IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameType) == existingAggregateVerifierEnv,
            "dgf impl does not match existing aggregate verifier"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactory.setImplementation, (gameType, newAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactory dgf = IDisputeGameFactory(disputeGameFactoryProxyEnv);

        require(dgf.gameImpls(gameType) == newAggregateVerifier, "dgf aggregate verifier mismatch");
        require(
            AggregateVerifier(newAggregateVerifier).TEE_IMAGE_HASH() == newTeeImageHashEnv,
            "new aggregate tee image hash mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
