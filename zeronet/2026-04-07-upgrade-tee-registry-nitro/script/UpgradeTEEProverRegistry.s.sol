// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";

interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
}

interface IProxy {
    function implementation() external view returns (address);
}

contract UpgradeTEEProverRegistry is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal teeProverRegistryProxyEnv;

    address internal newTeeProverRegistryImpl;
    address internal newNitroEnclaveVerifier;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        teeProverRegistryProxyEnv = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newTeeProverRegistryImpl = vm.parseJsonAddress({json: json, key: ".teeProverRegistryImpl"});
        newNitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (teeProverRegistryProxyEnv, newTeeProverRegistryImpl)),
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
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
