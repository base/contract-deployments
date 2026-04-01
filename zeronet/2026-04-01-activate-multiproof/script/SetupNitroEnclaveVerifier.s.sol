// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

interface INitroEnclaveVerifierAdmin {
    function owner() external view returns (address);
    function proofSubmitter() external view returns (address);
    function addVerifyRoute(uint8 zkCoProcessor, bytes4 selector, address verifier) external;
    function getZkVerifier(uint8 zkCoProcessor, bytes4 selector) external view returns (address);
    function setProofSubmitter(address submitter) external;
}

contract SetupNitroEnclaveVerifier is MultisigScript {
    uint8 internal constant ZK_COPROCESSOR_RISC_ZERO = 1;

    address internal teeProverRegistryOwnerEnv;
    address internal riscZeroVerifierRouterEnv;
    address internal nitroEnclaveVerifier;
    address internal riscZeroSetVerifier;
    address internal newTeeProverRegistryProxy;
    bytes32 internal riscZeroSetBuilderImageIdEnv;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        riscZeroVerifierRouterEnv = vm.envAddress("RISC0_VERIFIER_ROUTER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
        riscZeroSetVerifier = vm.parseJsonAddress({json: json, key: ".riscZeroSetVerifier"});
        newTeeProverRegistryProxy = vm.parseJsonAddress({json: json, key: ".teeProverRegistryProxy"});

        require(
            INitroEnclaveVerifierAdmin(nitroEnclaveVerifier).owner() == teeProverRegistryOwnerEnv,
            "Nitro owner != TEE_PROVER_REGISTRY_OWNER"
        );
        require(
            INitroEnclaveVerifierAdmin(nitroEnclaveVerifier).proofSubmitter() == teeProverRegistryOwnerEnv,
            "Nitro proofSubmitter is not the expected placeholder owner"
        );
        require(
            INitroEnclaveVerifierAdmin(nitroEnclaveVerifier)
                .getZkVerifier(ZK_COPROCESSOR_RISC_ZERO, _riscZeroSetVerifierSelector()) == riscZeroVerifierRouterEnv,
            "Nitro set-verifier route is not on the default router"
        );
    }

    /// @dev Builds the owner-only Nitro configuration batch executed by TEE_PROVER_REGISTRY_OWNER.
    ///      0. Add the selector-specific route that sends RISC Zero set-inclusion proofs
    ///         to the dedicated local RiscZeroSetVerifier.
    ///      1. Hand Nitro proof submission to the live TEEProverRegistry proxy.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: nitroEnclaveVerifier,
            data: abi.encodeCall(
                INitroEnclaveVerifierAdmin.addVerifyRoute,
                (ZK_COPROCESSOR_RISC_ZERO, _riscZeroSetVerifierSelector(), riscZeroSetVerifier)
            ),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: nitroEnclaveVerifier,
            data: abi.encodeCall(INitroEnclaveVerifierAdmin.setProofSubmitter, (newTeeProverRegistryProxy)),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        INitroEnclaveVerifierAdmin nitro = INitroEnclaveVerifierAdmin(nitroEnclaveVerifier);

        require(nitro.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");
        require(nitro.proofSubmitter() == newTeeProverRegistryProxy, "nitro proof submitter mismatch");
        require(
            nitro.getZkVerifier(ZK_COPROCESSOR_RISC_ZERO, _riscZeroSetVerifierSelector()) == riscZeroSetVerifier,
            "nitro route mismatch"
        );
    }

    function _riscZeroSetVerifierSelector() internal view returns (bytes4) {
        return bytes4(
            sha256(
                abi.encodePacked(
                    sha256("risc0.SetInclusionReceiptVerifierParameters"), riscZeroSetBuilderImageIdEnv, uint16(1) << 8
                )
            )
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return teeProverRegistryOwnerEnv;
    }
}
