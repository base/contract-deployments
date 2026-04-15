// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {
    INitroEnclaveVerifier,
    ZkCoProcessorConfig,
    ZkCoProcessorType
} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {RiscZeroSetVerifier, RiscZeroSetVerifierLib} from "lib/risc0-ethereum/contracts/src/RiscZeroSetVerifier.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";

contract DeployNitroVerifier is Script {
    address internal teeProverRegistryOwnerEnv;
    address internal nitroRevokerEnv;
    uint64 internal nitroInitialMaxTimeDiffSecondsEnv;
    bytes32 internal nitroInitialRootCertEnv;
    address internal riscZeroVerifierRouterEnv;
    address internal riscZeroSetVerifierEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;
    bytes32 internal nitroZkVerifierIdEnv;

    address public riscZeroSetVerifier;
    address public nitroEnclaveVerifier;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        nitroRevokerEnv = vm.envAddress("NITRO_REVOKER");
        nitroInitialMaxTimeDiffSecondsEnv = uint64(vm.envUint("NITRO_INITIAL_MAX_TIME_DIFF_SECONDS"));
        nitroInitialRootCertEnv = vm.envBytes32("NITRO_INITIAL_ROOT_CERT");
        riscZeroVerifierRouterEnv = vm.envAddress("RISC0_VERIFIER_ROUTER");
        riscZeroSetVerifierEnv = vm.envAddress("RISC0_SET_VERIFIER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");
        nitroZkVerifierIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_ID");
    }

    function run() external {
        bytes32[] memory trustedCerts = new bytes32[](0);
        uint64[] memory trustedCertExpiries = new uint64[](0);
        riscZeroSetVerifier = riscZeroSetVerifierEnv;

        vm.startBroadcast();

        nitroEnclaveVerifier = address(
            new NitroEnclaveVerifier({
                owner: msg.sender,
                initialMaxTimeDiff: nitroInitialMaxTimeDiffSecondsEnv,
                initializeTrustedCerts: trustedCerts,
                initializeTrustedCertExpiries: trustedCertExpiries,
                initialRootCert: nitroInitialRootCertEnv,
                initialProofSubmitter: teeProverRegistryOwnerEnv,
                initialRevoker: nitroRevokerEnv,
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                config: ZkCoProcessorConfig({
                    verifierId: nitroZkVerifierIdEnv, aggregatorId: bytes32(0), zkVerifier: riscZeroVerifierRouterEnv
                }),
                verifierProofId: bytes32(0)
            })
        );

        // Wire the selector-specific route that sends RISC Zero set-inclusion proofs
        // to the predeployed Sepolia RiscZeroSetVerifier. Ownership is retained by
        // msg.sender so that SetupNitroEnclaveVerifier can call setProofSubmitter
        // after the TEEProverRegistry proxy is deployed, then transfer ownership
        // to the multisig.
        NitroEnclaveVerifier(nitroEnclaveVerifier)
            .addVerifyRoute(
                ZkCoProcessorType.RiscZero,
                RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv),
                riscZeroSetVerifier
            );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _checkRiscZeroSetVerifier();
        _checkNitroEnclaveVerifier();
    }

    /// @dev Validates the configured Sepolia RISC Zero set verifier.
    ///      1. Check that VERIFIER points to the configured external router.
    ///      2. Check that SELECTOR matches the configured set-builder image ID.
    function _checkRiscZeroSetVerifier() internal view {
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(address(setVerifier.VERIFIER()) == riscZeroVerifierRouterEnv, "set verifier router mismatch");
        require(setVerifier.SELECTOR() == setVerifierSelector, "set verifier selector mismatch");
    }

    /// @dev Validates the NitroEnclaveVerifier deployment after route wiring.
    ///      Ownership remains with the deployer (msg.sender) at this stage; it will be
    ///      transferred to TEE_PROVER_REGISTRY_OWNER in SetupNitroEnclaveVerifier after
    ///      setProofSubmitter is called.
    ///      1. Check that maxTimeDiff matches NITRO_INITIAL_MAX_TIME_DIFF_SECONDS.
    ///      2. Check that rootCert matches NITRO_INITIAL_ROOT_CERT.
    ///      3. Check that proofSubmitter is the temporary owner placeholder.
    ///      4. Check that the default RISC Zero config points at the external router
    ///         and configured Nitro verifier image ID.
    ///      5. Check that the verifier proof ID is zero for the default route.
    ///      6. Check that the set-verifier selector route now points to the configured
    ///         Sepolia RiscZeroSetVerifier (wired via addVerifyRoute at deploy time).
    function _checkNitroEnclaveVerifier() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiffSecondsEnv, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCertEnv, "nitro root cert mismatch");
        require(nev.proofSubmitter() == teeProverRegistryOwnerEnv, "nitro placeholder submitter mismatch");
        require(nev.revoker() == nitroRevokerEnv, "nitro revoker mismatch");

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == nitroZkVerifierIdEnv, "nitro verifier id mismatch");
        require(cfg.aggregatorId == bytes32(0), "nitro aggregator id mismatch");
        require(cfg.zkVerifier == riscZeroVerifierRouterEnv, "nitro router mismatch");
        require(nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == bytes32(0), "nitro verifier proof id mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier).getZkVerifier(ZkCoProcessorType.RiscZero, setVerifierSelector)
                == riscZeroSetVerifier,
            "nitro set-verifier route mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("RiscZeroSetVerifier:", riscZeroSetVerifier);
        console.log("NitroEnclaveVerifier:", nitroEnclaveVerifier);
        console.log("RiscZeroVerifierRouter:", riscZeroVerifierRouterEnv);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "riscZeroSetVerifier", value: riscZeroSetVerifier});
        json = vm.serializeAddress({objectKey: root, valueKey: "nitroEnclaveVerifier", value: nitroEnclaveVerifier});
        json = vm.serializeAddress({
            objectKey: root, valueKey: "riscZeroVerifierRouter", value: riscZeroVerifierRouterEnv
        });
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
