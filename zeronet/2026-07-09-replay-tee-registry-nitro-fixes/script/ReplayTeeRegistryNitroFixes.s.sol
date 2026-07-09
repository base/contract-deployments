// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {ZkCoProcessorConfig, ZkCoProcessorType} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";

interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
}

interface IProxy {
    function implementation() external view returns (address);
}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

interface INitroEnclaveVerifierView {
    function owner() external view returns (address);
    function proofSubmitter() external view returns (address);
    function getZkConfig(ZkCoProcessorType zkCoProcessor) external view returns (ZkCoProcessorConfig memory);
}

contract ReplayTeeRegistryNitroFixes is MultisigScript {
    address internal immutable OWNER_SAFE_ENV = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable PROXY_ADMIN_ENV = vm.envAddress("L1_PROXY_ADMIN");
    address internal immutable TEE_PROVER_REGISTRY_PROXY_ENV = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
    address internal immutable TEE_PROVER_REGISTRY_OWNER_ENV = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal immutable EXISTING_AGGREGATE_VERIFIER_ENV = vm.envAddress("EXISTING_AGGREGATE_VERIFIER");
    bytes32 internal immutable NITRO_ZK_VERIFIER_ID_ENV = vm.envBytes32("NITRO_ZK_VERIFIER_ID");
    bytes32 internal immutable TEE_IMAGE_HASH_ENV = vm.envBytes32("TEE_IMAGE_HASH");

    address internal newNitroEnclaveVerifier;
    address internal newTeeProverRegistryImpl;
    address internal newAggregateVerifier;
    GameType internal gameType;

    function setUp() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newNitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
        newTeeProverRegistryImpl = vm.parseJsonAddress({json: json, key: ".teeProverRegistryImpl"});
        newAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});

        gameType = AggregateVerifier(newAggregateVerifier).gameType();

        require(
            IDisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(gameType) == EXISTING_AGGREGATE_VERIFIER_ENV,
            "dgf impl does not match existing aggregate verifier"
        );
        require(
            address(TEEProverRegistry(newTeeProverRegistryImpl).NITRO_VERIFIER()) == newNitroEnclaveVerifier,
            "tee registry impl nitro mismatch"
        );
        require(
            AggregateVerifier(newAggregateVerifier).TEE_IMAGE_HASH() == TEE_IMAGE_HASH_ENV, "tee image hash mismatch"
        );

        INitroEnclaveVerifierView nev = INitroEnclaveVerifierView(newNitroEnclaveVerifier);
        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(nev.owner() == TEE_PROVER_REGISTRY_OWNER_ENV, "nitro owner mismatch");
        require(nev.proofSubmitter() == TEE_PROVER_REGISTRY_PROXY_ENV, "nitro proof submitter mismatch");
        require(cfg.verifierId == NITRO_ZK_VERIFIER_ID_ENV, "nitro verifier id mismatch");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: PROXY_ADMIN_ENV,
            data: abi.encodeCall(IProxyAdmin.upgrade, (TEE_PROVER_REGISTRY_PROXY_ENV, newTeeProverRegistryImpl)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: DISPUTE_GAME_FACTORY_PROXY_ENV,
            data: abi.encodeCall(IDisputeGameFactory.setImplementation, (gameType, newAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        vm.prank(PROXY_ADMIN_ENV);
        require(
            IProxy(TEE_PROVER_REGISTRY_PROXY_ENV).implementation() == newTeeProverRegistryImpl,
            "tee registry implementation mismatch"
        );
        require(
            address(TEEProverRegistry(TEE_PROVER_REGISTRY_PROXY_ENV).NITRO_VERIFIER()) == newNitroEnclaveVerifier,
            "tee registry nitro mismatch"
        );
        require(
            IDisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(gameType) == newAggregateVerifier,
            "dgf aggregate verifier mismatch"
        );
        require(
            AggregateVerifier(newAggregateVerifier).TEE_IMAGE_HASH() == TEE_IMAGE_HASH_ENV, "tee image hash mismatch"
        );

        INitroEnclaveVerifierView nev = INitroEnclaveVerifierView(newNitroEnclaveVerifier);
        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(nev.owner() == TEE_PROVER_REGISTRY_OWNER_ENV, "nitro owner changed");
        require(nev.proofSubmitter() == TEE_PROVER_REGISTRY_PROXY_ENV, "nitro proof submitter changed");
        require(cfg.verifierId == NITRO_ZK_VERIFIER_ID_ENV, "nitro verifier id changed");
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE_ENV;
    }
}
