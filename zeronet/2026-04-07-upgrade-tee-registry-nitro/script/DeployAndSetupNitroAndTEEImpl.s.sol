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

interface ITEEProverRegistryImmutableViews {
    function NITRO_VERIFIER() external view returns (address);
    function DISPUTE_GAME_FACTORY() external view returns (address);
}

contract DeployAndSetupNitroAndTEEImpl is Script {
    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal nitroRevokerEnv;

    uint64 internal nitroInitialMaxTimeDiffSecondsEnv;
    bytes32 internal nitroInitialRootCertEnv;
    address internal riscZeroVerifierRouterEnv;
    bytes32 internal riscZeroSetBuilderImageIdEnv;
    bytes32 internal nitroZkVerifierIdEnv;

    address public riscZeroSetVerifier;
    address public nitroEnclaveVerifier;
    address public teeProverRegistryImpl;

    function setUp() public {
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryProxyEnv = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        nitroRevokerEnv = vm.envAddress("NITRO_REVOKER");

        nitroInitialMaxTimeDiffSecondsEnv = uint64(vm.envUint("NITRO_INITIAL_MAX_TIME_DIFF_SECONDS"));
        nitroInitialRootCertEnv = vm.envBytes32("NITRO_INITIAL_ROOT_CERT");
        riscZeroVerifierRouterEnv = vm.envAddress("RISC0_VERIFIER_ROUTER");
        riscZeroSetBuilderImageIdEnv = vm.envBytes32("RISC0_SET_BUILDER_IMAGE_ID");
        nitroZkVerifierIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_ID");

        require(nitroRevokerEnv != address(0), "NITRO_REVOKER must be non-zero");
    }

    function run() external {
        bytes32[] memory trustedCerts = new bytes32[](0);
        uint64[] memory trustedCertExpiries = new uint64[](0);

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

        NitroEnclaveVerifier(nitroEnclaveVerifier).addVerifyRoute(
            ZkCoProcessorType.RiscZero,
            RiscZeroSetVerifierLib.selector(riscZeroSetBuilderImageIdEnv),
            riscZeroSetVerifier
        );
        NitroEnclaveVerifier(nitroEnclaveVerifier).setProofSubmitter(teeProverRegistryProxyEnv);
        NitroEnclaveVerifier(nitroEnclaveVerifier).setRevoker(nitroRevokerEnv);
        NitroEnclaveVerifier(nitroEnclaveVerifier).transferOwnership(teeProverRegistryOwnerEnv);

        teeProverRegistryImpl = _deployTeeProverRegistryImpl(nitroEnclaveVerifier, disputeGameFactoryProxyEnv);

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _checkRiscZeroSetVerifier();
        _checkNitroEnclaveVerifier();
        _checkTeeProverRegistryImpl();
    }

    function _checkRiscZeroSetVerifier() internal view {
        RiscZeroSetVerifier setVerifier = RiscZeroSetVerifier(riscZeroSetVerifier);
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
            INitroEnclaveVerifier(nitroEnclaveVerifier).getZkVerifier(ZkCoProcessorType.RiscZero, setVerifierSelector)
                == riscZeroSetVerifier,
            "nitro set-verifier route mismatch"
        );
    }

    function _checkTeeProverRegistryImpl() internal view {
        ITEEProverRegistryImmutableViews registry = ITEEProverRegistryImmutableViews(teeProverRegistryImpl);
        require(address(registry.NITRO_VERIFIER()) == nitroEnclaveVerifier, "tee registry nitro mismatch");
        require(address(registry.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "tee registry dgf mismatch");
    }

    /// @dev Deploys TEEProverRegistry implementation without importing its source unit directly.
    ///      This avoids forcing this script's pragma to match TEEProverRegistry (=0.8.15),
    ///      while still producing the exact implementation bytecode.
    function _deployTeeProverRegistryImpl(address nitroVerifier, address disputeGameFactory) internal returns (address) {
        bytes memory creationCode = vm.getCode("src/multiproof/tee/TEEProverRegistry.sol:TEEProverRegistry");
        bytes memory initCode = abi.encodePacked(creationCode, abi.encode(nitroVerifier, disputeGameFactory));

        address impl;
        assembly ("memory-safe") {
            impl := create(0, add(initCode, 0x20), mload(initCode))
        }
        require(impl != address(0), "tee registry impl deployment failed");
        return impl;
    }

    function _writeAddresses() internal {
        console.log("RiscZeroSetVerifier:", riscZeroSetVerifier);
        console.log("NitroEnclaveVerifier:", nitroEnclaveVerifier);
        console.log("TEEProverRegistryImpl:", teeProverRegistryImpl);
        console.log("RiscZeroVerifierRouter:", riscZeroVerifierRouterEnv);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "riscZeroSetVerifier", value: riscZeroSetVerifier});
        json = vm.serializeAddress({objectKey: root, valueKey: "nitroEnclaveVerifier", value: nitroEnclaveVerifier});
        json = vm.serializeAddress({objectKey: root, valueKey: "teeProverRegistryImpl", value: teeProverRegistryImpl});
        json = vm.serializeAddress({
            objectKey: root, valueKey: "riscZeroVerifierRouter", value: riscZeroVerifierRouterEnv
        });
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
