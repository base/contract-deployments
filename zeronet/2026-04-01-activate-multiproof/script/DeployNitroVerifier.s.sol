// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {
    INitroEnclaveVerifier,
    ZkCoProcessorConfig,
    ZkCoProcessorType
} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {IRiscZeroVerifier} from "lib/risc0-ethereum/contracts/src/IRiscZeroVerifier.sol";
import {RiscZeroSetVerifier, RiscZeroSetVerifierLib} from "lib/risc0-ethereum/contracts/src/RiscZeroSetVerifier.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";

contract DeployNitroVerifier is Script {
    address internal teeProverRegistryOwnerEnv;
    uint64 internal nitroInitialMaxTimeDiffSecondsEnv;
    bytes32 internal nitroInitialRootCertEnv;
    address internal riscZeroVerifierRouterEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;
    bytes32 internal nitroZkVerifierIdEnv;

    address public riscZeroSetVerifier;
    address public nitroEnclaveVerifier;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        nitroInitialMaxTimeDiffSecondsEnv = uint64(vm.envUint("NITRO_INITIAL_MAX_TIME_DIFF_SECONDS"));
        nitroInitialRootCertEnv = vm.envBytes32("NITRO_INITIAL_ROOT_CERT");
        riscZeroVerifierRouterEnv = vm.envAddress("RISC0_VERIFIER_ROUTER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");
        nitroZkVerifierIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_ID");
    }

    function run() external {
        bytes32[] memory trustedCerts = new bytes32[](0);

        vm.startBroadcast();

        riscZeroSetVerifier = address(
            new RiscZeroSetVerifier({
                verifier: IRiscZeroVerifier(riscZeroVerifierRouterEnv),
                imageId: riscZeroSetBuilderImageIdEnv,
                _imageUrl: "https://gateway.pinata.cloud/ipfs/bafybeicclqbjn5ief3ycqif6wv3n3wr43szv2locrmml5h7d4fkrz4jrum"
            })
        );

        nitroEnclaveVerifier = address(
            new NitroEnclaveVerifier({
                owner: teeProverRegistryOwnerEnv,
                initialMaxTimeDiff: nitroInitialMaxTimeDiffSecondsEnv,
                initializeTrustedCerts: trustedCerts,
                initialRootCert: nitroInitialRootCertEnv,
                initialProofSubmitter: teeProverRegistryOwnerEnv,
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                config: ZkCoProcessorConfig({
                    verifierId: nitroZkVerifierIdEnv, aggregatorId: bytes32(0), zkVerifier: riscZeroVerifierRouterEnv
                }),
                verifierProofId: bytes32(0)
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _checkRiscZeroSetVerifier();
        _checkNitroEnclaveVerifier();
    }

    /// @dev Validates the local RISC Zero set verifier deployment.
    ///      1. Check that VERIFIER points to the configured external router.
    ///      2. Check that SELECTOR matches the configured set-builder image ID.
    function _checkRiscZeroSetVerifier() internal view {
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(address(setVerifier.VERIFIER()) == riscZeroVerifierRouterEnv, "set verifier router mismatch");
        require(setVerifier.SELECTOR() == setVerifierSelector, "set verifier selector mismatch");
    }

    /// @dev Validates the NitroEnclaveVerifier deployment before the owner Safe completes
    ///      the final route wiring in the upgrade batch.
    ///      1. Check that owner is set to TEE_PROVER_REGISTRY_OWNER.
    ///      2. Check that maxTimeDiff matches NITRO_INITIAL_MAX_TIME_DIFF_SECONDS.
    ///      3. Check that rootCert matches NITRO_INITIAL_ROOT_CERT.
    ///      4. Check that proofSubmitter is the temporary owner placeholder.
    ///      5. Check that the default RISC Zero config points at the external router
    ///         and configured Nitro verifier image ID.
    ///      6. Check that the verifier proof ID is zero for the default route.
    ///      7. Check that the set-verifier selector still resolves to the default router
    ///         before the owner Safe wires the dedicated route in the upgrade batch.
    function _checkNitroEnclaveVerifier() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(nev.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");
        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiffSecondsEnv, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCertEnv, "nitro root cert mismatch");
        require(nev.proofSubmitter() == teeProverRegistryOwnerEnv, "nitro placeholder submitter mismatch");

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == nitroZkVerifierIdEnv, "nitro verifier id mismatch");
        require(cfg.aggregatorId == bytes32(0), "nitro aggregator id mismatch");
        require(cfg.zkVerifier == riscZeroVerifierRouterEnv, "nitro router mismatch");
        require(nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == bytes32(0), "nitro verifier proof id mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier).getZkVerifier(ZkCoProcessorType.RiscZero, setVerifierSelector)
                == riscZeroVerifierRouterEnv,
            "nitro default verifier mismatch"
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
