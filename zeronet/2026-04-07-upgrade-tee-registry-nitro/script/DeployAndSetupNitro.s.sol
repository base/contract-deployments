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
    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryProxyEnv;
    address internal nitroRevokerEnv;

    uint64 internal nitroInitialMaxTimeDiffSecondsEnv;
    bytes32 internal nitroInitialRootCertEnv;
    address internal riscZeroVerifierRouterEnv;
    address internal riscZeroSetVerifierEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;
    bytes32 internal nitroZkVerifierIdEnv;

    address public nitroEnclaveVerifier;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryProxyEnv = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
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

        vm.startBroadcast();

        nitroEnclaveVerifier = address(
            new NitroEnclaveVerifier({
                owner: msg.sender,
                initialMaxTimeDiff: nitroInitialMaxTimeDiffSecondsEnv,
                initializeTrustedCerts: trustedCerts,
                initializeTrustedCertExpiries: trustedCertExpiries,
                initialRootCert: nitroInitialRootCertEnv,
                initialProofSubmitter: msg.sender,
                initialRevoker: address(0),
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                config: ZkCoProcessorConfig({
                    verifierId: nitroZkVerifierIdEnv, aggregatorId: bytes32(0), zkVerifier: riscZeroVerifierRouterEnv
                }),
                verifierProofId: bytes32(0)
            })
        );

        NitroEnclaveVerifier(nitroEnclaveVerifier)
            .addVerifyRoute({
                zkCoProcessor: ZkCoProcessorType.RiscZero,
                selector: RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv),
                verifier: riscZeroSetVerifierEnv
            });
        NitroEnclaveVerifier(nitroEnclaveVerifier).setProofSubmitter(teeProverRegistryProxyEnv);
        NitroEnclaveVerifier(nitroEnclaveVerifier).setRevoker(nitroRevokerEnv);
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
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifierEnv);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(address(setVerifier.VERIFIER()) == riscZeroVerifierRouterEnv, "set verifier router mismatch");
        require(setVerifier.SELECTOR() == setVerifierSelector, "set verifier selector mismatch");
    }

    function _checkNitroEnclaveVerifier() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);
        bytes4 setVerifierSelector = RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv);

        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiffSecondsEnv, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCertEnv, "nitro root cert mismatch");
        require(nev.proofSubmitter() == teeProverRegistryProxyEnv, "nitro proof submitter mismatch");
        require(nev.revoker() == nitroRevokerEnv, "nitro revoker mismatch");
        require(nev.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == nitroZkVerifierIdEnv, "nitro verifier id mismatch");
        require(cfg.aggregatorId == bytes32(0), "nitro aggregator id mismatch");
        require(cfg.zkVerifier == riscZeroVerifierRouterEnv, "nitro router mismatch");
        require(nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == bytes32(0), "nitro verifier proof id mismatch");
        require(
            INitroEnclaveVerifier(nitroEnclaveVerifier)
                .getZkVerifier({_zkCoProcessor: ZkCoProcessorType.RiscZero, _selector: setVerifierSelector})
            == riscZeroSetVerifierEnv,
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
