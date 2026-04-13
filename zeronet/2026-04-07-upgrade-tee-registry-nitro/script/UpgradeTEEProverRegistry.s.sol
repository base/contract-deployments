// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
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

contract UpgradeTeeProverRegistry is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal teeProverRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;

    address internal newTeeProverRegistryImpl;
    address internal newNitroEnclaveVerifier;
    address internal newAggregateVerifier;

    // Derived from the deployed AggregateVerifier.
    GameType internal gameType;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        teeProverRegistryProxyEnv = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newTeeProverRegistryImpl = vm.parseJsonAddress({json: json, key: ".teeProverRegistryImpl"});
        newNitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
        newAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});

        gameType = AggregateVerifier(newAggregateVerifier).gameType();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        // 0. Upgrade the TEEProverRegistry proxy to the new implementation (points to new NEV).
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (teeProverRegistryProxyEnv, newTeeProverRegistryImpl)),
            value: 0
        });

        // 1. Register the new AggregateVerifier in the DisputeGameFactory.
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactory.setImplementation, (gameType, newAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        vm.prank(proxyAdminEnv);
        require(
            IProxy(teeProverRegistryProxyEnv).implementation() == newTeeProverRegistryImpl,
            "tee registry implementation mismatch"
        );
        require(
            address(TEEProverRegistry(teeProverRegistryProxyEnv).NITRO_VERIFIER()) == newNitroEnclaveVerifier,
            "tee registry nitro mismatch"
        );
        require(
            IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameType) == newAggregateVerifier,
            "dgf aggregate verifier mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
