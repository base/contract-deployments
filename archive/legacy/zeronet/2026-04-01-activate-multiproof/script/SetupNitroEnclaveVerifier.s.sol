// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {
    INitroEnclaveVerifier,
    ZkCoProcessorConfig,
    ZkCoProcessorType
} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {RiscZeroSetVerifierLib} from "lib/risc0-ethereum/contracts/src/RiscZeroSetVerifier.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";

/// @title SetupNitroEnclaveVerifier
/// @notice Executed by the deployer EOA (via Ledger) after DeployMultiproofStack has deployed
///         the TEEProverRegistry proxy. Sets the proof submitter to the TEEProverRegistry proxy
///         and transfers NitroEnclaveVerifier ownership to the configured multisig owner.
contract SetupNitroEnclaveVerifier is Script {
    address internal teeProverRegistryOwnerEnv;
    address internal riscZeroVerifierRouterEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;

    address internal nitroEnclaveVerifier;
    address internal riscZeroSetVerifier;
    address internal teeProverRegistryProxy;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        riscZeroVerifierRouterEnv = vm.envAddress("RISC0_VERIFIER_ROUTER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
        riscZeroSetVerifier = vm.parseJsonAddress({json: json, key: ".riscZeroSetVerifier"});
        teeProverRegistryProxy = vm.parseJsonAddress({json: json, key: ".teeProverRegistryProxy"});
    }

    function run() external {
        vm.startBroadcast();

        // 0. Set the proof submitter to the TEEProverRegistry proxy so the registry
        //    can submit proofs to the NitroEnclaveVerifier.
        NitroEnclaveVerifier(nitroEnclaveVerifier).setProofSubmitter(teeProverRegistryProxy);

        // 1. Transfer ownership to the configured multisig owner now that all
        //    deployer-only configuration is complete.
        NitroEnclaveVerifier(nitroEnclaveVerifier).transferOwnership(teeProverRegistryOwnerEnv);

        vm.stopBroadcast();

        _postCheck();
    }

    function _postCheck() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(nev.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");
        require(nev.proofSubmitter() == teeProverRegistryProxy, "nitro proof submitter mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier).getZkVerifier(ZkCoProcessorType.RiscZero, setVerifierSelector)
                == riscZeroSetVerifier,
            "nitro set-verifier route mismatch"
        );
    }
}
