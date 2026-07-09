// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {
    INitroEnclaveVerifier,
    ZkCoProcessorConfig,
    ZkCoProcessorType
} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {RiscZeroSetVerifier, RiscZeroSetVerifierLib} from "lib/risc0-ethereum/contracts/src/RiscZeroSetVerifier.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";

contract DeployAndSetupNitroFinal is Script {
    address internal immutable EXISTING_NITRO_ENCLAVE_VERIFIER_ENV = vm.envAddress("EXISTING_NITRO_ENCLAVE_VERIFIER");
    address internal immutable TEE_PROVER_REGISTRY_OWNER_ENV = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
    address internal immutable TEE_PROVER_REGISTRY_PROXY_ENV = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
    address internal immutable NITRO_REVOKER_ENV = vm.envAddress("NITRO_REVOKER");
    bytes32 internal immutable RISC_ZERO_SET_BUILDER_IMAGE_ID_ENV = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");
    bytes32 internal immutable CURRENT_NITRO_ZK_VERIFIER_ID_ENV = vm.envBytes32("CURRENT_NITRO_ZK_VERIFIER_ID");
    bytes32 internal immutable NITRO_ZK_VERIFIER_ID_ENV = vm.envBytes32("NITRO_ZK_VERIFIER_ID");

    uint64 internal nitroInitialMaxTimeDiff;
    bytes32 internal nitroInitialRootCert;
    address internal riscZeroVerifierRouter;
    address internal riscZeroSetVerifier;

    address public nitroEnclaveVerifier;

    function setUp() public {
        require(CURRENT_NITRO_ZK_VERIFIER_ID_ENV != NITRO_ZK_VERIFIER_ID_ENV, "verifier id already target");

        NitroEnclaveVerifier existingNev = NitroEnclaveVerifier(EXISTING_NITRO_ENCLAVE_VERIFIER_ENV);
        nitroInitialMaxTimeDiff = existingNev.maxTimeDiff();
        nitroInitialRootCert = existingNev.rootCert();

        ZkCoProcessorConfig memory cfg = existingNev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == CURRENT_NITRO_ZK_VERIFIER_ID_ENV, "unexpected current verifier id");
        require(cfg.aggregatorId == bytes32(0), "unexpected current aggregator id");

        riscZeroVerifierRouter = cfg.zkVerifier;

        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(RISC_ZERO_SET_BUILDER_IMAGE_ID_ENV);
        riscZeroSetVerifier = INitroEnclaveVerifier(EXISTING_NITRO_ENCLAVE_VERIFIER_ENV)
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
                initialRevoker: NITRO_REVOKER_ENV,
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                config: ZkCoProcessorConfig({
                    verifierId: NITRO_ZK_VERIFIER_ID_ENV, aggregatorId: bytes32(0), zkVerifier: riscZeroVerifierRouter
                }),
                verifierProofId: bytes32(0)
            })
        );

        NitroEnclaveVerifier(nitroEnclaveVerifier)
            .addVerifyRoute({
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                selector: RiscZeroSetVerifierLib.selector(RISC_ZERO_SET_BUILDER_IMAGE_ID_ENV),
                verifier: riscZeroSetVerifier
            });
        NitroEnclaveVerifier(nitroEnclaveVerifier).setProofSubmitter(TEE_PROVER_REGISTRY_PROXY_ENV);
        NitroEnclaveVerifier(nitroEnclaveVerifier).transferOwnership(TEE_PROVER_REGISTRY_OWNER_ENV);

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(RISC_ZERO_SET_BUILDER_IMAGE_ID_ENV);

        require(address(setVerifier.VERIFIER()) == riscZeroVerifierRouter, "set verifier router mismatch");
        require(setVerifier.SELECTOR() == setVerifierSelector, "set verifier selector mismatch");

        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiff, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCert, "nitro root cert mismatch");
        require(nev.proofSubmitter() == TEE_PROVER_REGISTRY_PROXY_ENV, "nitro proof submitter mismatch");
        require(nev.revoker() == NITRO_REVOKER_ENV, "nitro revoker mismatch");
        require(nev.owner() == TEE_PROVER_REGISTRY_OWNER_ENV, "nitro owner mismatch");

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == NITRO_ZK_VERIFIER_ID_ENV, "nitro verifier id mismatch");
        require(cfg.aggregatorId == bytes32(0), "nitro aggregator id mismatch");
        require(cfg.zkVerifier == riscZeroVerifierRouter, "nitro router mismatch");
        require(nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == bytes32(0), "nitro verifier proof id mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier).getZkVerifier(ZkCoProcessorType.RiscZero, setVerifierSelector)
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
