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

contract DeployAndSetupNitro is Script {
    address internal existingNitroEnclaveVerifierEnv;
    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryProxyEnv;
    address internal nitroRevokerEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;

    // Derived from the existing NitroEnclaveVerifier at setUp time.
    uint64 internal nitroInitialMaxTimeDiff;
    bytes32 internal nitroInitialRootCert;
    address internal riscZeroVerifierRouter;
    address internal riscZeroSetVerifier;
    bytes32 internal nitroZkVerifierId;

    address public nitroEnclaveVerifier;

    function setUp() public {
        existingNitroEnclaveVerifierEnv = vm.envAddress("EXISTING_NITRO_ENCLAVE_VERIFIER");
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryProxyEnv = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
        nitroRevokerEnv = vm.envAddress("NITRO_REVOKER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");

        // Read config from the existing NitroEnclaveVerifier to ensure continuity.
        NitroEnclaveVerifier existingNev = NitroEnclaveVerifier(existingNitroEnclaveVerifierEnv);
        nitroInitialMaxTimeDiff = existingNev.maxTimeDiff();
        nitroInitialRootCert = existingNev.rootCert();

        ZkCoProcessorConfig memory cfg = existingNev.getZkConfig(ZkCoProcessorType.RiscZero);
        riscZeroVerifierRouter = cfg.zkVerifier;
        nitroZkVerifierId = cfg.verifierId;

        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);
        riscZeroSetVerifier = INitroEnclaveVerifier(existingNitroEnclaveVerifierEnv)
            .getZkVerifier({_zkCoProcessor: ZkCoProcessorType.RiscZero, _selector: setVerifierSelector});
    }

    function run() external {
        bytes32[] memory trustedCerts = new bytes32[](0);
        uint64[] memory trustedCertExpiries = new uint64[](0);

        vm.startBroadcast();

        nitroEnclaveVerifier = address(
            new NitroEnclaveVerifier({
                owner: msg.sender,
                initialMaxTimeDiff: nitroInitialMaxTimeDiff,
                initializeTrustedCerts: trustedCerts,
                initializeTrustedCertExpiries: trustedCertExpiries,
                initialRootCert: nitroInitialRootCert,
                initialProofSubmitter: msg.sender,
                initialRevoker: nitroRevokerEnv,
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                config: ZkCoProcessorConfig({
                    verifierId: nitroZkVerifierId, aggregatorId: bytes32(0), zkVerifier: riscZeroVerifierRouter
                }),
                verifierProofId: bytes32(0)
            })
        );

        NitroEnclaveVerifier(nitroEnclaveVerifier).addVerifyRoute({
            zkCoProcessor: ZkCoProcessorType.RiscZero,
            selector: RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv),
            verifier: riscZeroSetVerifier
        });
        NitroEnclaveVerifier(nitroEnclaveVerifier).setProofSubmitter(teeProverRegistryProxyEnv);
        NitroEnclaveVerifier(nitroEnclaveVerifier).transferOwnership(teeProverRegistryOwnerEnv);

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _checkRiscZeroSetVerifier();
        _checkNitroEnclaveVerifier();
    }

    function _checkRiscZeroSetVerifier() internal view {
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(address(setVerifier.VERIFIER()) == riscZeroVerifierRouter, "set verifier router mismatch");
        require(setVerifier.SELECTOR() == setVerifierSelector, "set verifier selector mismatch");
    }

    function _checkNitroEnclaveVerifier() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiff, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCert, "nitro root cert mismatch");
        require(nev.proofSubmitter() == teeProverRegistryProxyEnv, "nitro proof submitter mismatch");
        require(nev.revoker() == nitroRevokerEnv, "nitro revoker mismatch");
        require(nev.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == nitroZkVerifierId, "nitro verifier id mismatch");
        require(cfg.aggregatorId == bytes32(0), "nitro aggregator id mismatch");
        require(cfg.zkVerifier == riscZeroVerifierRouter, "nitro router mismatch");
        require(nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == bytes32(0), "nitro verifier proof id mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier)
                .getZkVerifier({_zkCoProcessor: ZkCoProcessorType.RiscZero, _selector: setVerifierSelector})
            == riscZeroSetVerifier,
            "nitro set-verifier route mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("NitroEnclaveVerifier:", nitroEnclaveVerifier);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "nitroEnclaveVerifier", value: nitroEnclaveVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
